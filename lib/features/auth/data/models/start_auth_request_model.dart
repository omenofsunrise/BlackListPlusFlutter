class StartAuthRequestModel {
  final String phone;
  final String userType;
  final bool moderate;

  StartAuthRequestModel({
    required this.phone,
    this.userType = 'blacklist_plus',
    this.moderate = true,
  });

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'user_type': userType, 'moderate': moderate};
  }
}
