class CallConfirmRequestModel {
  final String? checkId;
  final String? name;
  final String? phone;
  final String userType;

  const CallConfirmRequestModel({
    this.checkId,
    this.name,
    this.phone,
    this.userType = 'blacklist_plus',
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'phone': phone,
      'check_id': checkId,
      'user_type': userType,
    };
    if (name != null && name!.isNotEmpty) {
      body['name'] = name;
    }
    return body;
  }
}
