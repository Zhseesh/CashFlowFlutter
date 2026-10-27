import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'attachment_service.dart';

class ParsedTransaction {
  final TransactionRecord transaction;
  final String? attachmentBase64; // Berisi "data|.ext"

  ParsedTransaction(this.transaction, this.attachmentBase64);
}

class JsonBackupService {
  static const schemaVersion = 2; // Naikkan versi skema karena ada base64

  static Future<File> export({
    required List<Category> categories,
    required List<TransactionRecord> transactions,
    required double saldoAwal,
  }) async {
    final txList = <Map<String, dynamic>>[];

    for (final t in transactions) {
      final map = t.toMap();
      
      // Jika ada lampiran, baca file dan ubah ke Base64
      if (t.attachmentPath != null) {
        final file = await AttachmentService.resolve(t.attachmentPath);
        if (file != null && await file.exists()) {
          final bytes = await file.readAsBytes();
          final ext = p.extension(file.path); // misal .jpg
          // Simpan base64 + ekstensi dengan separator "|"
          map['attachment_base64'] = '${base64Encode(bytes)}|$ext';
        }
      }
      txList.add(map);
    }

    final payload = {
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'saldo_awal': saldoAwal,
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': txList,
    };
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/CashFlow_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }

  static Future<({double saldoAwal, List<ParsedTransaction> transactions})> parse(String raw) async {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['schema_version'] == null) throw const FormatException('schema_version tidak ditemukan');
    
    final saldoAwal = (map['saldo_awal'] as num?)?.toDouble() ?? 0;
    final txRaw = (map['transactions'] as List? ?? []);
    
    final parsedList = <ParsedTransaction>[];
    
    for (final e in txRaw) {
      final txMap = Map<String, dynamic>.from(e as Map);
      
      String? base64Data;
      if (txMap.containsKey('attachment_base64')) {
        base64Data = txMap.remove('attachment_base64') as String?;
        // Hapus path lama karena file fisik belum tentu ada di HP ini
        txMap['attachment_path'] = null; 
      }
      
      final tx = TransactionRecord.fromMap(txMap);
      parsedList.add(ParsedTransaction(tx, base64Data));
    }
    
    return (saldoAwal: saldoAwal, transactions: parsedList);
  }
}