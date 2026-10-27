import 'dart:convert';

class TransactionRecord {
  final int? id;
  final int? walletId;
  final String title;
  final double amount;
  final String type;
  final int? categoryId;
  final String categoryName;
  final int dateMillis;
  final String? note;
  final List<String> attachments;

  const TransactionRecord({
    this.id,
    this.walletId,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.categoryName,
    required this.dateMillis,
    this.note,
    this.attachments = const [],
  });

  bool get isIncome => type == 'INCOME';
  bool get hasAttachment => attachments.isNotEmpty;
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(dateMillis);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        if (walletId != null) 'wallet_id': walletId,
        'title': title,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'category_name': categoryName,
        'date_millis': dateMillis,
        'note': note,
        'attachment_paths': jsonEncode(attachments),
      };

  factory TransactionRecord.fromMap(Map<String, dynamic> m) {
    List<String> parsedAttachments = [];
    if (m['attachment_paths'] != null) {
      parsedAttachments = (jsonDecode(m['attachment_paths']) as List).cast<String>();
    } else if (m['attachment_path'] != null) {
      // Fallback untuk data lama
      parsedAttachments = [m['attachment_path'] as String];
    }

    return TransactionRecord(
      id: m['id'] as int?,
      walletId: m['wallet_id'] as int?,
      title: m['title'] as String,
      amount: (m['amount'] as num).toDouble(),
      type: m['type'] as String,
      categoryId: m['category_id'] as int?,
      categoryName: m['category_name'] as String,
      dateMillis: m['date_millis'] as int,
      note: m['note'] as String?,
      attachments: parsedAttachments,
    );
  }
}