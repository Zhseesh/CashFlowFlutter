import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class JsonBackupService {
  static const schemaVersion = 1;

  static Future<File> export({
    required List<Category> categories,
    required List<TransactionRecord> transactions,
    required double saldoAwal,
  }) async {
    final payload = {
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'saldo_awal': saldoAwal,
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/CashFlow_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }

  static Future<({double saldoAwal, List<TransactionRecord> transactions})> parse(String raw) async {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['schema_version'] == null) throw const FormatException('schema_version tidak ditemukan');
    final saldoAwal = (map['saldo_awal'] as num?)?.toDouble() ?? 0;
    final txs = (map['transactions'] as List? ?? [])
        .map((e) => TransactionRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return (saldoAwal: saldoAwal, transactions: txs);
  }
}