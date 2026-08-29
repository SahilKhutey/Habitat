// Habitat Profile Service Layer
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

class ProfileService {
  final ProfileRepository _repository;

  ProfileService(this._repository);

  UserProfileModel getProfile() {
    final raw = _repository.getProfile();
    return UserProfileModel(
      id: raw.id,
      displayName: raw.displayName,
      bio: raw.bio,
      avatarUrl: raw.avatarUrl,
      disciplineLevel: raw.disciplineLevel,
      createdAt: raw.createdAt,
    );
  }

  void updateProfile({
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) {
    if (displayName.trim().isEmpty) {
      throw ArgumentError('Display name cannot be empty');
    }
    _repository.updateProfile(
      displayName: displayName.trim(),
      bio: bio.trim(),
      avatarUrl: avatarUrl,
    );
  }
}
