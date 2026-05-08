class StartAuthRequestModel {
  final String phone;
  final String userType;

  StartAuthRequestModel({
    required this.phone,
    this.userType = 'blacklist_plus',
  });

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'user_type': userType};
  }
}
