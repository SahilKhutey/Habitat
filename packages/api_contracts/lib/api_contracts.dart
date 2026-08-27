/// Shared API Data Contracts for Habitat Discipline Platform
library api_contracts;

class HealthResponseDto {
  final String status;
  final String service;
  final String version;
  final String? database;
  final String timestamp;

  HealthResponseDto({
    required this.status,
    required this.service,
    required this.version,
    this.database,
    required this.timestamp,
  });

  factory HealthResponseDto.fromJson(Map<String, dynamic> json) {
    return HealthResponseDto(
      status: json['status'] as String? ?? 'ok',
      service: json['service'] as String? ?? 'discipline-api',
      version: json['version'] as String? ?? '0.1.0',
      database: json['database'] as String?,
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'service': service,
        'version': version,
        'database': database,
        'timestamp': timestamp,
      };
}
