class CompanyCommonInfo {
  final int id;
  final DateTime licenceDate;

  CompanyCommonInfo({required this.id, required this.licenceDate});

  factory CompanyCommonInfo.fromJson(Map<String, dynamic> json) {
    return CompanyCommonInfo(id: json['id'] as int, licenceDate: DateTime.parse(json['licenceDate'] as String));
  }
}
