import 'dart:convert';
import '../models/category.dart';
import '../models/transaction.dart';
import 'attachment_service.dart';

class ParsedTransaction {
  final TransactionRecord transaction;
  final List<String> attachmentBases64; 

  ParsedTransaction(this.transaction, this.attachmentBases64);
}

class JsonBackupService {
  static const schemaVersion = 3;

  static Future<String> export({
    required List<Category> categories,
    required List<TransactionRecord> transactions,
    required double saldoAwal,
  }) async {
    final txList = <Map<String, dynamic>>[];

    for (final t in transactions) {
      final map = t.toMap();
      final b64List = <String>[];
      for (final filePath in t.attachments) {
        final file = await AttachmentService.resolve(filePath);
        if (file != null && await file.exists()) {
          final bytes = await file.readAsBytes();
          final ext = file.path.split('.').last;
          b64List.add('${base64Encode(bytes)}|.$ext');
        }
      }
      map['attachment_bases64'] = b64List;
      txList.add(map);
    }

    final payload = {
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'saldo_awal': saldoAwal,
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': txList,
    };
    
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<({double saldoAwal, List<ParsedTransaction> transactions})> parse(String raw) async {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final saldoAwal = (map['saldo_awal'] as num?)?.toDouble() ?? 0;
    final txRaw = (map['transactions'] as List? ?? []);
    final parsedList = <ParsedTransaction>[];
    
    for (final e in txRaw) {
      final txMap = Map<String, dynamic>.from(e as Map);
      List<String> b64List = [];
      
      if (txMap.containsKey('attachment_bases64')) {
        b64List = (txMap.remove('attachment_bases64') as List).cast<String>();
      } else if (txMap.containsKey('attachment_base64')) {
        final single = txMap.remove('attachment_base64') as String?;
        if (single != null) b64List.add(single);
      }
      
      final tx = TransactionRecord.fromMap(txMap);
      parsedList.add(ParsedTransaction(tx, b64List));
    }
    return (saldoAwal: saldoAwal, transactions: parsedList);
  }
}