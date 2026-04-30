class RefreshTokenRequestModel {
  final String accessToken;
  final String refreshToken;

  RefreshTokenRequestModel({
    required this.accessToken,
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken, 'refreshToken': refreshToken};
  }
}
