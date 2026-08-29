// Habitat User Profile Domain Model
import 'package:flutter/foundation.dart';

@immutable
class UserProfileModel {
  final String id;
  final String displayName;
  final String username;
  final String bio;
  final String avatarUrl;
  final String disciplineLevel;
  final DateTime createdAt;

  const UserProfileModel({
    required this.id,
    required this.displayName,
    this.username = 'discipline_explorer',
    this.bio = 'Building the life I want to live with Habitat.',
    this.avatarUrl = '',
    this.disciplineLevel = 'Explorer',
    required this.createdAt,
  });

  UserProfileModel copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? disciplineLevel,
  }) =>
      UserProfileModel(
        id: id,
        displayName: displayName ?? this.displayName,
        username: username ?? this.username,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        disciplineLevel: disciplineLevel ?? this.disciplineLevel,
        createdAt: createdAt,
      );
}
