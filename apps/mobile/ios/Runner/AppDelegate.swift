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

        // 1. Configure Hardware Audio Session to Override Mute Switch
        configureAudioSession()

        // 2. Setup Method Channel for Native Alarm Execution
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let alarmChannel = FlutterMethodChannel(name: "habitat/native_alarm", binaryMessenger: controller.binaryMessenger)

        alarmChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "scheduleExactAlarm":
                guard let args = call.arguments as? [String: Any],
                      let missionId = args["missionId"] as? String,
                      let taskTitle = args["taskTitle"] as? String,
                      let triggerEpochMs = args["triggerEpochMs"] as? Int64 else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing alarm arguments", details: nil))
                    return
                }
                let sirenVolume = args["sirenVolume"] as? Int ?? 70
                self?.scheduleNotification(missionId: missionId, title: taskTitle, triggerEpochMs: triggerEpochMs, volume: sirenVolume)
                result(true)

            case "stopSiren":
                self?.stopSirenAudio()
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category: \(error)")
        }
    }

    private func scheduleNotification(missionId: String, title: String, triggerEpochMs: Int64, volume: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔴 \(title)"
        content.body = "Mission Active. Complete physical task to dismiss alarm."
        content.sound = UNNotificationSound.defaultCriticalSound(withAudioVolume: Float(volume) / 100.0)
        content.userInfo = ["mission_id": missionId]

        let triggerDate = Date(timeIntervalSince1970: Double(triggerEpochMs) / 1000.0)
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(identifier: "mission_\(missionId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func stopSirenAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
