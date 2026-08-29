// Habitat Nap Timer Application Controller
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/nap_entry.dart';
import '../domain/services/nap_service.dart';

class NapController extends ChangeNotifier {
  final NapService _napService;
  final LocalDatabase _database;

  late NapSummaryModel summary;
  Timer? _timer;

  NapController({
    required NapService napService,
    required LocalDatabase database,
  })  : _napService = napService,
        _database = database {
    summary = _napService.getTodaySummary();
    _database.changes.addListener(_onDatabaseChanged);
    _checkTimerState();
  }

  int get elapsedSeconds {
    final active = summary.activeNap;
    if (active == null || !active.isRunning) return 0;
    return DateTime.now().difference(active.startedAt).inSeconds;
  }

  String get formattedTimer {
    final total = elapsedSeconds;
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    if (total >= 3600) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  void startNap() {
    _napService.startNap();
  }

  void stopNap() {
    _napService.stopNap();
  }

  void _checkTimerState() {
    if (summary.isRunning) {
      if (_timer == null || !_timer!.isActive) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          notifyListeners();
        });
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _onDatabaseChanged() {
    summary = _napService.getTodaySummary();
    _checkTimerState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _database.changes.removeListener(_onDatabaseChanged);
    super.dispose();
  }
}
