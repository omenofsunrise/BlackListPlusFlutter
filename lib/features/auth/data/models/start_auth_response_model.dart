class StartAuthResponseModel {
  final String checkId;
  final String callPhone;
  final bool nameRequired;
  final bool success;
  final String? message;

  StartAuthResponseModel({
    required this.checkId,
    required this.callPhone,
    this.nameRequired = false,
    this.success = true,
    this.message,
  });

  factory StartAuthResponseModel.fromJson(Map<String, dynamic> json) {
    final checkId = json['check_id'] ?? json['checkId'];
    final callPhone = json['call_phone'] ?? json['callPhone'];
    final nameRequiredRaw = json['name_required'] ?? json['nameRequired'];
    final successRaw = json['success'];
    final messageRaw = json['message'];
    final nameRequired = nameRequiredRaw is bool
        ? nameRequiredRaw
        : nameRequiredRaw == true;
    final success = successRaw is bool ? successRaw : true;
    final message = messageRaw?.toString();
    return StartAuthResponseModel(
      checkId: (checkId ?? '').toString(),
      callPhone: (callPhone ?? '').toString(),
      nameRequired: nameRequired,
      success: success,
      message: (message != null && message.trim().isNotEmpty)
          ? message.trim()
          : null,
    );
  }
}
