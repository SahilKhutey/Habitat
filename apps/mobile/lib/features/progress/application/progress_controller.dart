// Habitat Master Progress Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/progress_overview_model.dart';
import '../domain/services/progress_service.dart';

class ProgressController extends ChangeNotifier {
  final ProgressService _progressService;
  final LocalDatabase _database;

  String selectedTimeframe = 'TODAY'; // 'TODAY', 'WEEK', 'MONTH'
  late ProgressOverviewModel overview;
  bool isLoading = false;

  ProgressController({
    required ProgressService progressService,
    required LocalDatabase database,
  })  : _progressService = progressService,
        _database = database {
    overview = _progressService.getOverview();
    _database.changes.addListener(_onDataChanged);
  }

  void setTimeframe(String timeframe) {
    selectedTimeframe = timeframe;
    notifyListeners();
  }

  void refresh() {
    isLoading = true;
    notifyListeners();
    overview = _progressService.getOverview();
    isLoading = false;
    notifyListeners();
  }

  void _onDataChanged() {
    overview = _progressService.getOverview();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
