class LocalDebt {
  final String id;
  final String debtorName;
  final int amountRub;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? comment;
  final bool isPaid;
  final DateTime? paidAt;

  const LocalDebt({
    required this.id,
    required this.debtorName,
    required this.amountRub,
    required this.createdAt,
    this.dueDate,
    this.comment,
    this.isPaid = false,
    this.paidAt,
  });

  LocalDebt copyWith({
    String? debtorName,
    int? amountRub,
    DateTime? dueDate,
    String? comment,
    bool? isPaid,
    DateTime? paidAt,
    bool clearDueDate = false,
    bool clearPaidAt = false,
  }) {
    return LocalDebt(
      id: id,
      debtorName: debtorName ?? this.debtorName,
      amountRub: amountRub ?? this.amountRub,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      comment: comment ?? this.comment,
      isPaid: isPaid ?? this.isPaid,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'debtorName': debtorName,
        'amountRub': amountRub,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'comment': comment,
        'isPaid': isPaid,
        'paidAt': paidAt?.toIso8601String(),
      };

  factory LocalDebt.fromJson(Map<String, dynamic> json) {
    return LocalDebt(
      id: json['id'] as String,
      debtorName: json['debtorName'] as String,
      amountRub: (json['amountRub'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      comment: json['comment'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
    );
  }
}
