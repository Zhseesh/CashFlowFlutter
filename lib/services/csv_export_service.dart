import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';

class CsvExportService {
  static Future<File?> export({
    required String walletName,
    required List<TransactionRecord> transactions,
    required double saldoAwal,
  }) async {
    final buf = StringBuffer();
    buf.writeln('ID,Tanggal,Waktu,Tipe,Kategori,Judul,Catatan,Nominal,Saldo Berjalan');
    double running = saldoAwal;
    for (final t in transactions.reversed) {
      running += t.isIncome ? t.amount : -t.amount;
      final d = t.date;
      final dateStr = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      buf.writeln([
        t.id ?? '',
        dateStr,
        timeStr,
        t.type,
        _esc(t.categoryName),
        _esc(t.title),
        _esc(t.note ?? ''),
        t.amount.toStringAsFixed(2),
        running.toStringAsFixed(2),
      ].join(','));
    }
    
    final safeName = walletName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/CashFlow_${safeName}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buf.toString(), flush: true);
    return file;
  }

  static String _esc(String s) => '"${s.replaceAll('"', '""')}"';
}