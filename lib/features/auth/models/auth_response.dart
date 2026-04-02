class AuthResponse {
  final String accessToken;
  final String? tokenType;

  AuthResponse({
    required this.accessToken,
    this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: (json['access_token'] ?? json['token'] ?? '').toString(),
      tokenType: json['token_type']?.toString(),
    );
  }
}