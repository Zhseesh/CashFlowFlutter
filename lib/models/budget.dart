class Budget {
  final int? id;
  final int walletId;
  final String categoryName;
  final double limitAmount;

  const Budget({
    this.id,
    required this.walletId,
    required this.categoryName,
    required this.limitAmount,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'wallet_id': walletId,
        'category_name': categoryName,
        'limit_amount': limitAmount,
      };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        id: m['id'] as int?,
        walletId: m['wallet_id'] as int,
        categoryName: m['category_name'] as String,
        limitAmount: (m['limit_amount'] as num).toDouble(),
      );
}