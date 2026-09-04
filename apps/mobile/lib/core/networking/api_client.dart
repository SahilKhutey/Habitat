// Habitat Central HTTP & API Client with Auth Interceptor
import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import '../config/app_config.dart';

class ProofChallengeResponse {
  final String sessionId;
  final String sessionNonce;
  final String missionId;
  final String promptInstruction;

  const ProofChallengeResponse({
    required this.sessionId,
    required this.sessionNonce,
    required this.missionId,
    required this.promptInstruction,
  });

  factory ProofChallengeResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ProofChallengeResponse(
      sessionId: data['sessionId'] as String? ?? '',
      sessionNonce: data['sessionNonce'] as String? ?? '',
      missionId: data['missionId'] as String? ?? '',
      promptInstruction: data['promptInstruction'] as String? ?? '',
    );
  }
}

class UploadSessionResponse {
  final String uploadId;
  final String proofId;
  final String uploadUrl;
  final String downloadUrl;
  final String objectKey;

  const UploadSessionResponse({
    required this.uploadId,
    required this.proofId,
    required this.uploadUrl,
    required this.downloadUrl,
    required this.objectKey,
  });

  factory UploadSessionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UploadSessionResponse(
      uploadId: data['uploadId'] as String? ?? '',
      proofId: data['proofId'] as String? ?? '',
      uploadUrl: data['uploadUrl'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      objectKey: data['objectKey'] as String? ?? '',
    );
  }
}

class ServerVerificationResponse {
  final bool isValid;
  final String decision;
  final double truthScore;
  final int repsVerified;
  final String? rejectionReason;
  final List<String> flags;
  final bool nonceValidated;

  const ServerVerificationResponse({
    required this.isValid,
    required this.decision,
    this.truthScore = 1.0,
    this.repsVerified = 0,
    this.rejectionReason,
    this.flags = const [],
    this.nonceValidated = false,
  });

  factory ServerVerificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ServerVerificationResponse(
      isValid: data['isValid'] as bool? ?? (data['decision'] == 'ACCEPT'),
      decision: data['decision'] as String? ?? 'REJECT',
      truthScore: (data['truthScore'] as num?)?.toDouble() ?? 0.0,
      repsVerified: data['repsVerified'] as int? ?? 0,
      rejectionReason: data['rejectionReason'] as String?,
      flags: (data['flags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      nonceValidated: data['nonceValidated'] as bool? ?? false,
    );
  }
}

class HabitatApiClient {
  final Dio _dio;
  final String baseUrl;

  HabitatApiClient({
    String? baseUrl,
    Dio? dio,
  })  : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final headers = AuthTokenManager.getAuthHeaders();
        options.headers.addAll(headers);
        return handler.next(options);
      },
    ));
  }

  /// 1. Request cryptographic proof challenge
  Future<ProofChallengeResponse> requestChallenge({
    required String missionId,
  }) async {
    final response = await _dio.post(
      '/verification/challenge',
      data: {'missionId': missionId},
    );
    return ProofChallengeResponse.fromJson(response.data);
  }

  /// 2. Create authoritative upload session
  Future<UploadSessionResponse> createUploadSession({
    required String missionId,
    required String type, // PHOTO or VIDEO
    required String mimeType,
    required int sizeBytes,
    int? durationSeconds,
    String? sessionId,
    String? sessionNonce,
  }) async {
    final response = await _dio.post(
      '/proofs/upload-session',
      data: {
        'missionId': missionId,
        'type': type,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (sessionId != null) 'sessionId': sessionId,
        if (sessionNonce != null) 'sessionNonce': sessionNonce,
      },
    );
    return UploadSessionResponse.fromJson(response.data);
  }

  /// 3. Upload raw media bytes to presigned / local storage endpoint
  Future<void> uploadMediaBytes({
    required String uploadUrl,
    required List<int> mediaBytes,
    required String mimeType,
  }) async {
    await _dio.put(
      uploadUrl,
      data: Stream.fromIterable([mediaBytes]),
      options: Options(
        headers: {
          'Content-Type': mimeType,
          'Content-Length': mediaBytes.length,
        },
      ),
    );
  }

  /// 4. Complete upload handshake
  Future<void> completeUpload(String proofId) async {
    await _dio.post('/proofs/$proofId/complete');
  }

  /// 5. Execute server-side real vision verification
  Future<ServerVerificationResponse> verifyRealVision({
    required String proofId,
    Map<String, dynamic>? policy,
  }) async {
    final response = await _dio.post(
      '/proofs/$proofId/verify-real-vision',
      data: {'policy': policy ?? {}},
    );
    return ServerVerificationResponse.fromJson(response.data);
  }
}
