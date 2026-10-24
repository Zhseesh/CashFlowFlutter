import 'package:intl/intl.dart';

import '../models/models.dart';

/// CSV UTF-8 (dengan BOM agar Excel membaca karakter dengan benar).
class CsvExporter {
  CsvExporter._();

  static const headers = [
    'ID',
    'Tanggal',
    'Waktu',
    'Tipe',
    'Kategori',
    'Judul',
    'Catatan',
    'Nominal',
    'Saldo Berjalan',
  ];

  /// [transactions] harus terurut naik menurut tanggal.
  /// Nominal bertanda: pemasukan positif, pengeluaran negatif.
  /// [delimiter] ';' (Excel/Sheets locale Indonesia) atau ','.
  static String build({
    required List<CashTransaction> transactions,
    required double openingBalance,
    String delimiter = ';',
  }) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('HH:mm');
    final decimal = delimiter == ';' ? ',' : '.';

    final b = StringBuffer('﻿');
    b.write('${headers.map((h) => escape(h, delimiter)).join(delimiter)}\r\n');

    var running = openingBalance;
    for (final tx in transactions) {
      running += tx.signedAmount;
      final row = [
        '${tx.id ?? ''}',
        dateFmt.format(tx.date),
        timeFmt.format(tx.date),
        tx.type.label,
        _text(tx.categoryName),
        _text(tx.title),
        _text(tx.note ?? ''),
        _num(tx.signedAmount, decimal),
        _num(running, decimal),
      ];
      b.write('${row.map((f) => escape(f, delimiter)).join(delimiter)}\r\n');
    }
    return b.toString();
  }

  static String _num(double v, String decimal) {
    final s = v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
    return decimal == '.' ? s : s.replaceAll('.', decimal);
  }

  /// Mencegah formula injection di spreadsheet (=, +, -, @ di awal teks).
  static String _text(String s) {
    if (s.isNotEmpty && '=+-@'.contains(s[0])) return "'$s";
    return s;
  }

  static String escape(String field, String delimiter) {
    final needsQuote = field.contains(delimiter) ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuote) return field;
    return '"${field.replaceAll('"', '""')}"';
  }
}
