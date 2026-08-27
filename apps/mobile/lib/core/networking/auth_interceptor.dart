// Client-Side Authentication Interceptor & Token Manager

class AuthTokenManager {
  static String? _accessToken;
  static String? _refreshToken;

  static void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;

  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  static Map<String, String> getAuthHeaders() {
    if (_accessToken != null) {
      return {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }
}
