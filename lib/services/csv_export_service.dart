import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/transaction.dart';
import 'export_service.dart';

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
    
    final safeName = ExportService.sanitizeName(walletName);
    final fileName = 'CashFlow_${safeName}_${DateTime.now().millisecondsSinceEpoch}.csv';
    
    final savedPath = await ExportService.saveToPublicDownloads(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(buf.toString())),
      mimeType: 'text/csv',
    );

    if (savedPath == null) return null;
    return File(savedPath);
  }

  static String _esc(String s) => '"${s.replaceAll('"', '""')}"';
}