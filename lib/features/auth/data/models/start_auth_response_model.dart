class StartAuthResponseModel {
  final String checkId;
  final String callPhone;
  final bool nameRequired;

  StartAuthResponseModel({
    required this.checkId,
    required this.callPhone,
    this.nameRequired = false,
  });

  factory StartAuthResponseModel.fromJson(Map<String, dynamic> json) {
    final checkId = json['check_id'] ?? json['checkId'];
    final callPhone = json['call_phone'] ?? json['callPhone'];
    final nameRequiredRaw = json['name_required'] ?? json['nameRequired'];
    final nameRequired = nameRequiredRaw is bool
        ? nameRequiredRaw
        : nameRequiredRaw == true;
    return StartAuthResponseModel(
      checkId: (checkId ?? '').toString(),
      callPhone: (callPhone ?? '').toString(),
      nameRequired: nameRequired,
    );
  }
}
