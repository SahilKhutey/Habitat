// Habitat Privacy Settings Domain Model
import 'package:flutter/foundation.dart';

@immutable
class PrivacySettingsModel {
  final bool analyticsEnabled;
  final bool dataSharingEnabled;
  final bool localFirstNoticeAccepted;

  const PrivacySettingsModel({
    this.analyticsEnabled = false,
    this.dataSharingEnabled = false,
    this.localFirstNoticeAccepted = true,
  });

  PrivacySettingsModel copyWith({
    bool? analyticsEnabled,
    bool? dataSharingEnabled,
    bool? localFirstNoticeAccepted,
  }) =>
      PrivacySettingsModel(
        analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
        dataSharingEnabled: dataSharingEnabled ?? this.dataSharingEnabled,
        localFirstNoticeAccepted:
            localFirstNoticeAccepted ?? this.localFirstNoticeAccepted,
      );

  Map<String, dynamic> toMap() => {
        'analytics': analyticsEnabled,
        'dataSharing': dataSharingEnabled,
        'localFirstNoticeAccepted': localFirstNoticeAccepted,
      };

  factory PrivacySettingsModel.fromMap(Map<String, dynamic> map) =>
      PrivacySettingsModel(
        analyticsEnabled: map['analytics'] ?? false,
        dataSharingEnabled: map['dataSharing'] ?? false,
        localFirstNoticeAccepted: map['localFirstNoticeAccepted'] ?? true,
      );
}
