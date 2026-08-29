// Habitat Alarms Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/alarm_model.dart';
import '../domain/services/alarm_service.dart';

class AlarmController extends ChangeNotifier {
  final AlarmService _alarmService;
  final LocalDatabase _database;

  String activeFilter = 'ALL';
  List<TaskAlarmModel> alarms = [];
  bool isLoading = false;

  AlarmController({
    required AlarmService alarmService,
    required LocalDatabase database,
  })  : _alarmService = alarmService,
        _database = database {
    _database.changes.addListener(_refreshFromData);
  }

  void load() {
    isLoading = true;
    notifyListeners();
    _refresh();
  }

  void setFilter(String filter) {
    activeFilter = filter;
    _refresh();
  }

  Future<void> toggleAlarm(String alarmId, bool isEnabled) async {
    await _alarmService.toggleAlarm(alarmId, isEnabled);
    _refresh();
  }

  void _refreshFromData() => _refresh();

  void _refresh() {
    alarms = _alarmService.getAlarmsByFilter(activeFilter);
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_refreshFromData);
    super.dispose();
  }
}
