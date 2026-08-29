// Habitat Privacy Service Layer
import '../models/privacy_settings.dart';
import '../repositories/profile_repository.dart';

class PrivacyService {
  final ProfileRepository _repository;

  PrivacyService(this._repository);

  PrivacySettingsModel getPrivacySettings() {
    return PrivacySettingsModel.fromMap(_repository.getPrivacySettings());
  }

  void updatePrivacySettings(PrivacySettingsModel settings) {
    _repository.setPrivacySettings(settings.toMap());
  }
}
