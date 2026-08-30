// Habitat Water Repository
import '../../../../database/local_database.dart';
import '../models/water_entry.dart';
import 'health_repository.dart';

class WaterRepository extends HealthRepository {
  WaterRepository(LocalDatabase database) : super(database);

  List<WaterEntryModel> getTodayEntries() => getWaterEntries(DateTime.now());
}
