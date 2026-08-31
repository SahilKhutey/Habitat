import UIKit
import Flutter
import AVFoundation
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var audioPlayer: AVAudioPlayer?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // 1. Configure Hardware Audio Session — overrides mute switch via .playback category
        configureAudioSession()

        // 2. Request notification permission (alert + sound + badge; NOT criticalAlert —
        //    that requires a special Apple entitlement. Time Sensitive is sufficient.)
        requestNotificationPermission()

        // 3. Register MethodChannels for native alarm operations
        let controller = window?.rootViewController as! FlutterViewController
        let channels = [
            FlutterMethodChannel(name: "com.habitat.app/native_alarm", binaryMessenger: controller.binaryMessenger),
            FlutterMethodChannel(name: "habitat/native_alarm", binaryMessenger: controller.binaryMessenger)
        ]

        let methodHandler: FlutterMethodCallHandler = { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            switch call.method {

            case "scheduleExactAlarm":
                guard let args = call.arguments as? [String: Any],
                      let missionId     = args["missionId"]     as? String,
                      let taskTitle     = args["taskTitle"]      as? String,
                      let triggerEpochMs = args["triggerEpochMs"] as? Int64 else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing alarm arguments", details: nil))
                    return
                }
                let sirenVolume  = args["sirenVolume"]  as? Int ?? 70
                let attemptIndex = args["attemptIndex"] as? Int ?? 1

                // Schedule a 6-notification escalation chain starting at triggerEpochMs
                // (T+0, T+5, T+10, T+15, T+20, T+25 minutes)
                self.scheduleAlarmChain(
                    missionId: missionId,
                    taskTitle: taskTitle,
                    triggerEpochMs: triggerEpochMs,
                    baseVolumePercent: sirenVolume,
                    startAttempt: attemptIndex
                )
                result(true)

            case "cancelAlarm":
                guard let args = call.arguments as? [String: Any],
                      let missionId = args["missionId"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing missionId", details: nil))
                    return
                }
                self.cancelAlarmChain(missionId: missionId)
                result(true)

            case "stopSiren":
                self.stopSirenAudio()
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        for ch in channels {
            ch.setMethodCallHandler(methodHandler)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Notification Permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("[Habitat] Notification permission error: \(error)")
            } else {
                print("[Habitat] Notification permission granted: \(granted)")
            }
        }
    }

    // MARK: - Alarm Chain Scheduling

    /// Schedules up to 6 notifications: T+0, T+5, T+10, T+15, T+20, T+25 minutes.
    /// Each notification uses Time Sensitive interruption level (iOS 15+) to break
    /// through Focus modes without requiring the criticalAlert entitlement.
    ///
    /// Volume ramp: attempt 1 → base%, 2 → 85%, 3+ → 100%
    private func scheduleAlarmChain(
        missionId: String,
        taskTitle: String,
        triggerEpochMs: Int64,
        baseVolumePercent: Int,
        startAttempt: Int
    ) {
        let center = UNUserNotificationCenter.current()
        let baseDate = Date(timeIntervalSince1970: Double(triggerEpochMs) / 1000.0)
        let maxAttempts = 6

        for i in 0..<maxAttempts {
            let attempt = startAttempt + i
            let offset = TimeInterval(i * 5 * 60) // 5-minute intervals
            let fireDate = baseDate.addingTimeInterval(offset)

            // Skip dates in the past
            guard fireDate > Date() else { continue }

            let volumePercent: Int
            switch attempt {
            case 1:  volumePercent = baseVolumePercent
            case 2:  volumePercent = 85
            default: volumePercent = 100
            }

            let content = UNMutableNotificationContent()
            content.title = "🔴 \(taskTitle)"
            content.body  = attempt == 1
                ? "Mission Active — complete your task to disarm."
                : "Escalation \(attempt)/\(maxAttempts) — volume at \(volumePercent)%. Disarm now."

            // Time Sensitive interruption level — breaks through Focus/DND
            // without requiring the criticalAlert Apple entitlement.
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }

            // Alarm sound — use system default alarm tone
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm_siren"))
                            ?? UNNotificationSound.defaultCriticalSound(withAudioVolume: Float(volumePercent) / 100.0)

            content.userInfo = [
                "mission_id":   missionId,
                "attempt_index": attempt,
                "task_title":   taskTitle
            ]

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "habitat_alarm_\(missionId)_attempt_\(attempt)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("[Habitat] Failed to schedule notification \(identifier): \(error)")
                } else {
                    print("[Habitat] Scheduled alarm notification \(identifier) for \(fireDate)")
                }
            }
        }
    }

    // MARK: - Alarm Cancellation

    /// Cancels all 6 escalation notifications for a given missionId.
    private func cancelAlarmChain(missionId: String) {
        let identifiers = (1...7).map { attempt in
            "habitat_alarm_\(missionId)_attempt_\(attempt)"
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
        print("[Habitat] Cancelled alarm chain for mission: \(missionId)")
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Habitat] Failed to configure AVAudioSession: \(error)")
        }
    }

    private func stopSirenAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
