/// Тело POST /auth/call/confirm — точно как в waypay_react_library
/// (lib/api/authCall.confirmCallAuth):
/// {
///   phone: string,
///   check_id: string,
///   user_type: string,
///   name?: string,
/// }
///
/// React всегда добавляет поле `name` в тело (если значение undefined,
/// JSON.stringify его просто опускает). Здесь повторяем то же поведение:
/// добавляем `name` в JSON только тогда, когда оно реально заполнено.
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
