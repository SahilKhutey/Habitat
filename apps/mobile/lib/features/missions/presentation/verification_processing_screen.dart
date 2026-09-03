// Real Verification Processing Screen & Telemetry HUD
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../../../../database/local_database.dart';
import '../../../../services/mission_execution_service.dart';

class VerificationProcessingScreen extends StatefulWidget {
  final String? attemptId;
  final String? taskId;
  final Future<bool>? verificationFuture;

  const VerificationProcessingScreen({
    super.key,
    this.attemptId,
    this.taskId,
    this.verificationFuture,
  });

  @override
  State<VerificationProcessingScreen> createState() => _VerificationProcessingScreenState();
}

class _VerificationProcessingScreenState extends State<VerificationProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  bool _isProcessing = true;
  bool _hasFailed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _executeVerification();
  }

  Future<void> _executeVerification() async {
    if (widget.verificationFuture != null) {
      try {
        final passed = await widget.verificationFuture!;
        if (!mounted) return;
        if (passed) {
          Navigator.of(context).pushReplacementNamed('/missions/success');
        } else {
          setState(() {
            _isProcessing = false;
            _hasFailed = true;
            _errorMessage = 'Biomechanical verification failed. Motion criteria not satisfied.';
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _hasFailed = true;
          _errorMessage = 'Verification error: ${e.toString()}';
        });
      }
      return;
    }

    if (widget.attemptId != null) {
      final db = LocalDatabase.instance;
      final attempt = db.getAttempt(widget.attemptId!);
      if (attempt != null && attempt.status == 'COMPLETED') {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/missions/success');
        }
      } else {
        setState(() {
          _isProcessing = false;
          _hasFailed = attempt?.status == 'FAILED';
          _errorMessage = attempt?.status == 'FAILED'
              ? 'Verification rejected by proof audit.'
              : 'Proof submitted. Awaiting verification results.';
        });
      }
    } else {
      // Idle monitoring state
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                RotationTransition(
                  turns: _radarController,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.amberFocus.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.radar, color: AppColors.amberFocus, size: 60),
                  ),
                )
              else if (_hasFailed)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.crimsonAlert, width: 2),
                  ),
                  child: const Icon(Icons.error_outline, color: AppColors.crimsonAlert, size: 54),
                )
              else
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.amberFocus, width: 2),
                  ),
                  child: const Icon(Icons.hourglass_top, color: AppColors.amberFocus, size: 54),
                ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                _hasFailed
                    ? 'VERIFICATION REJECTED'
                    : (_isProcessing ? 'AUDITING PROOF TELEMETRY' : 'VERIFICATION PENDING'),
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorMessage ??
                    (_isProcessing
                        ? 'Running MoveNet computer vision & motion validation...'
                        : 'No active verification task running.'),
                style: const TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              if (_hasFailed || !_isProcessing) ...[
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('RETURN TO DASHBOARD'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
