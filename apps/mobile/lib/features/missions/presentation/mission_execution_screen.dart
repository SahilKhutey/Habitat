// Habitat Mission Execution & Verification HUD Screen
import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/colors.dart';
import '../../../core/design_system/tokens/radii.dart';
import '../../../core/design_system/tokens/spacing.dart';
import '../../../core/design_system/tokens/typography.dart';
import '../../../core/platform/media/native_camera_proof_pipeline.dart';
import '../../../database/local_database.dart';
import '../../../services/mission_execution_service.dart';

enum MissionScreenState {
  ready,
  capturing,
  verifying,
  verified,
  failed,
  completed,
}

class MissionExecutionScreen extends StatefulWidget {
  final String taskId;
  final String? alarmId;

  const MissionExecutionScreen({
    super.key,
    required this.taskId,
    this.alarmId,
  });

  @override
  State<MissionExecutionScreen> createState() => _MissionExecutionScreenState();
}

class _MissionExecutionScreenState extends State<MissionExecutionScreen> {
  late final LocalDatabase _database;
  late final MissionExecutionService _missionService;
  late final NativeCameraProofPipeline _cameraPipeline;

  LocalTask? _task;
  LocalTaskAttempt? _attempt;
  MissionScreenState _state = MissionScreenState.ready;
  String? _errorMessage;
  int _earnedXp = 0;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _database = LocalDatabase.instance;
    _missionService = MissionExecutionService(database: _database);
    _cameraPipeline = NativeCameraProofPipeline();
    _initMission();
  }

  Future<void> _initMission() async {
    _task = _database.getTask(widget.taskId);
    if (_task != null) {
      final attempt = await _missionService.start(_task!.id, alarmId: widget.alarmId);
      setState(() {
        _attempt = attempt;
      });
    }
  }

  Future<void> _handleCapture() async {
    if (_task == null || _attempt == null) return;

    setState(() {
      _state = MissionScreenState.capturing;
      _errorMessage = null;
    });

    final isVideo = _task!.taskType == 'VIDEO' || _task!.requiresVideo;
    final proof = isVideo
        ? await _cameraPipeline.captureVideoProof(
            taskId: _task!.id,
            attemptId: _attempt!.id,
            durationSeconds: 5, // Valid 5s video
          )
        : await _cameraPipeline.capturePhotoProof(
            taskId: _task!.id,
            attemptId: _attempt!.id,
          );

    setState(() {
      _state = MissionScreenState.verifying;
    });

    final result = await _missionService.submitProof(
      _attempt!.id,
      ProofSubmission(
        type: isVideo ? 'VIDEO' : 'PHOTO',
        filePath: proof.filePath,
        sha256Checksum: proof.sha256Checksum,
        durationSeconds: proof.durationSeconds,
      ),
    );

    if (result.isPassed) {
      setState(() {
        _state = MissionScreenState.verified;
      });
      _handleComplete();
    } else {
      setState(() {
        _state = MissionScreenState.failed;
        _errorMessage = result.failureReason ?? 'Verification failed';
      });
    }
  }

  Future<void> _handleComplete() async {
    if (_attempt == null) return;
    final res = await _missionService.complete(_attempt!.id);
    if (mounted) {
      setState(() {
        _earnedXp = res.earnedXp;
        _currentStreak = res.currentStreak;
        _state = MissionScreenState.completed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return const Scaffold(
        backgroundColor: HabitatColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: HabitatColors.growthGreen)),
      );
    }

    final isVideo = _task!.taskType == 'VIDEO' || _task!.requiresVideo;

    return Scaffold(
      backgroundColor: HabitatColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mission HUD',
          style: HabitatTypography.titleMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HabitatSpacing.lg),
          child: Column(
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(HabitatSpacing.md),
                decoration: BoxDecoration(
                  color: HabitatColors.darkSurface,
                  borderRadius: HabitatRadius.radiusCard,
                  border: Border.all(color: HabitatColors.darkBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: HabitatColors.growthSoft,
                      child: Icon(
                        isVideo ? Icons.videocam : Icons.camera_alt,
                        color: HabitatColors.growthGreen,
                      ),
                    ),
                    const SizedBox(width: HabitatSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _task!.title,
                            style: HabitatTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Required Proof: ${isVideo ? "Motion Video (>=3s)" : "Photo Evidence"}',
                            style: HabitatTypography.bodySmall.copyWith(
                              color: HabitatColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: HabitatSpacing.lg),

              // Viewfinder / Interactive Canvas
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: HabitatRadius.radiusCard,
                    border: Border.all(color: HabitatColors.darkBorder),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder Grid Overlay
                      Center(
                        child: Icon(
                          isVideo ? Icons.accessibility_new : Icons.crop_free,
                          size: 120,
                          color: HabitatColors.youngLeaf.withOpacity(0.3),
                        ),
                      ),
                      if (_state == MissionScreenState.verifying)
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: HabitatColors.growthGreen),
                            SizedBox(height: HabitatSpacing.md),
                            Text(
                              'Running MoveNet Radar & Liveness...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      if (_state == MissionScreenState.failed)
                        Container(
                          padding: const EdgeInsets.all(HabitatSpacing.lg),
                          margin: const EdgeInsets.all(HabitatSpacing.lg),
                          decoration: BoxDecoration(
                            color: HabitatColors.crimsonAlert.withOpacity(0.9),
                            borderRadius: HabitatRadius.radiusCard,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 48),
                              const SizedBox(height: HabitatSpacing.sm),
                              Text(
                                _errorMessage ?? 'Verification failed',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (_state == MissionScreenState.completed)
                        Container(
                          padding: const EdgeInsets.all(HabitatSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: HabitatColors.growthGreen, size: 64),
                              const SizedBox(height: HabitatSpacing.md),
                              const Text(
                                'MISSION COMPLETE!',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: HabitatSpacing.sm),
                              Text(
                                '+$_earnedXp XP  •  🔥 $_currentStreak Day Streak',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: HabitatColors.growthGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: HabitatSpacing.lg),

              // Action Control Bar
              if (_state == MissionScreenState.ready || _state == MissionScreenState.failed)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleCapture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HabitatColors.growthGreen,
                      foregroundColor: HabitatColors.forest,
                      shape: const RoundedRectangleBorder(
                        borderRadius: HabitatRadius.radiusButton,
                      ),
                    ),
                    child: Text(
                      _state == MissionScreenState.failed ? 'Try Again' : 'Capture & Verify Proof',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else if (_state == MissionScreenState.completed)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HabitatColors.growthGreen,
                      foregroundColor: HabitatColors.forest,
                      shape: const RoundedRectangleBorder(
                        borderRadius: HabitatRadius.radiusButton,
                      ),
                    ),
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
