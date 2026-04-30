class RefreshTokenResponseModel {
  final String accessToken;

  RefreshTokenResponseModel({required this.accessToken});

  factory RefreshTokenResponseModel.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseModel(
      accessToken: (json['access_token'] ?? json['accessToken']) as String,
    );
  }
}
