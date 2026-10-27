class TransactionRecord {
  final int? id;
  final int? walletId; // Tambahan
  final String title;
  final double amount;
  final String type;
  final int? categoryId;
  final String categoryName;
  final int dateMillis;
  final String? note;
  final String? attachmentPath;

  const TransactionRecord({
    this.id,
    this.walletId, // Tambahan
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.categoryName,
    required this.dateMillis,
    this.note,
    this.attachmentPath,
  });

  bool get isIncome => type == 'INCOME';
  bool get hasAttachment => attachmentPath != null;
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMillis);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (walletId != null) 'wallet_id': walletId, // Tambahan
        'title': title,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'category_name': categoryName,
        'date_millis': dateMillis,
        'note': note,
        'attachment_path': attachmentPath,
      };

  factory TransactionRecord.fromMap(Map<String, dynamic> m) => TransactionRecord(
        id: m['id'] as int?,
        walletId: m['wallet_id'] as int?, // Tambahan
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: m['type'] as String,
        categoryId: m['category_id'] as int?,
        categoryName: m['category_name'] as String,
        dateMillis: m['date_millis'] as int,
        note: m['note'] as String?,
        attachmentPath: m['attachment_path'] as String?,
      );
}