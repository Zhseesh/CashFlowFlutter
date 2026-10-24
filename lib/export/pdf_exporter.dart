import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/models.dart';
import '../utils/format.dart';

/// Laporan PDF A4: kop, rekap saldo, grafik batang bulanan, tabel mutasi,
/// dan penomoran halaman otomatis.
class PdfExporter {
  PdfExporter._();

  static final _emerald = PdfColor.fromHex('#115E59');
  static final _income = PdfColor.fromHex('#10B981');
  static final _expense = PdfColor.fromHex('#E11D48');
  static final _muted = PdfColor.fromHex('#64748B');
  static final _line = PdfColor.fromHex('#CBD5E1');
  static final _zebra = PdfColor.fromHex('#F1F5F9');

  /// [transactions] terurut naik; [openingBalance] = saldo sebelum periode.
  static Future<Uint8List> build({
    required List<CashTransaction> transactions,
    required double openingBalance,
    required String periodLabel,
  }) async {
    final totalIncome = transactions
        .where((t) => t.type == TxType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == TxType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
    final closing = openingBalance + totalIncome - totalExpense;
    final months = monthlyOf(transactions);
    final printed = '${Fmt.date(DateTime.now())} ${Fmt.time(DateTime.now())}';

    final doc = pw.Document(
      title: 'Laporan Arus Kas',
      author: 'Cash Flow',
      creator: 'Cash Flow',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cash Flow - dicetak $printed',
                  style: pw.TextStyle(fontSize: 8, color: _muted)),
              pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ),
        build: (ctx) => [
          _kop(periodLabel, printed),
          pw.SizedBox(height: 14),
          _summary(openingBalance, totalIncome, totalExpense, closing),
          pw.SizedBox(height: 18),
          _chart(months),
          pw.SizedBox(height: 18),
          pw.Text('Rincian Mutasi Transaksi',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold, color: _emerald)),
          pw.SizedBox(height: 6),
          _table(transactions, openingBalance),
        ],
      ),
    );

    return doc.save();
  }

  /// Total per bulan dari daftar transaksi (maksimal 12 bulan terakhir).
  static List<MonthTotal> monthlyOf(List<CashTransaction> txs) {
    final map = <DateTime, List<double>>{};
    for (final t in txs) {
      final d = t.date;
      final key = DateTime(d.year, d.month);
      final v = map.putIfAbsent(key, () => [0, 0]);
      if (t.type == TxType.income) {
        v[0] += t.amount;
      } else {
        v[1] += t.amount;
      }
    }
    final keys = map.keys.toList()..sort();
    final last = keys.length > 12 ? keys.sublist(keys.length - 12) : keys;
    return last
        .map((m) =>
            MonthTotal(month: m, income: map[m]![0], expense: map[m]![1]))
        .toList();
  }

  /// Font bawaan PDF hanya mendukung Latin-1.
  static String _safe(String s) => String.fromCharCodes(
      s.runes.map((r) => r <= 0xFF ? r : 0x3F));

  static pw.Widget _kop(String period, String printed) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LAPORAN ARUS KAS',
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _emerald)),
                pw.SizedBox(height: 2),
                pw.Text('Periode: ${_safe(period)}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Text('Tanggal cetak: $printed',
                style: pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 3, color: _emerald),
      ],
    );
  }

  static pw.Widget _summary(
      double opening, double income, double expense, double closing) {
    pw.Widget box(String label, double value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _muted)),
              pw.SizedBox(height: 3),
              pw.Text(Fmt.rupiah(value),
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      );
    }

    return pw.Row(children: [
      box('Saldo Awal', opening, PdfColors.black),
      pw.SizedBox(width: 8),
      box('Total Pemasukan', income, _income),
      pw.SizedBox(width: 8),
      box('Total Pengeluaran', expense, _expense),
      pw.SizedBox(width: 8),
      box('Sisa Saldo', closing, _emerald),
    ]);
  }

  static pw.Widget _chart(List<MonthTotal> months) {
    const chartHeight = 110.0;
    var maxV = 0.0;
    for (final m in months) {
      if (m.income > maxV) maxV = m.income;
      if (m.expense > maxV) maxV = m.expense;
    }

    pw.Widget bar(double v, PdfColor c) {
      final h = maxV <= 0 ? 0.0 : chartHeight * v / maxV;
      return pw.Container(width: 11, height: h < 1 ? 1 : h, color: c);
    }

    pw.Widget legend(String text, PdfColor c) => pw.Row(children: [
          pw.Container(width: 8, height: 8, color: c),
          pw.SizedBox(width: 4),
          pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(width: 10),
        ]);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Perbandingan Pemasukan vs Pengeluaran per Bulan',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _emerald)),
            pw.Row(children: [
              legend('Pemasukan', _income),
              legend('Pengeluaran', _expense),
            ]),
          ],
        ),
        pw.SizedBox(height: 6),
        if (months.isEmpty)
          pw.Text('Belum ada data pada periode ini.',
              style: pw.TextStyle(fontSize: 9, color: _muted))
        else ...[
          pw.Text('Skala maksimum: ${Fmt.rupiah(maxV)}',
              style: pw.TextStyle(fontSize: 7, color: _muted)),
          pw.SizedBox(height: 4),
          pw.Container(
            height: chartHeight + 4,
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (final m in months)
                  pw.Expanded(
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        bar(m.income, _income),
                        pw.SizedBox(width: 2),
                        bar(m.expense, _expense),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Row(children: [
            for (final m in months)
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text(Fmt.monthYearShort(m.month),
                      style: const pw.TextStyle(fontSize: 7)),
                ),
              ),
          ]),
        ],
      ],
    );
  }

  static pw.Widget _table(List<CashTransaction> txs, double opening) {
    final rows = <List<String>>[
      ['', '', 'Saldo awal', '', '', '', Fmt.number(opening)],
    ];
    var running = opening;
    for (var i = 0; i < txs.length; i++) {
      final t = txs[i];
      running += t.signedAmount;
      final desc = (t.note == null || t.note!.trim().isEmpty)
          ? t.title
          : '${t.title} (${t.note})';
      rows.add([
        '${i + 1}',
        Fmt.dateShort(t.date),
        _safe(desc),
        _safe(t.categoryName),
        t.type == TxType.income ? Fmt.number(t.amount) : '',
        t.type == TxType.expense ? Fmt.number(t.amount) : '',
        Fmt.number(running),
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: const [
        'No',
        'Tanggal',
        'Keterangan',
        'Kategori',
        'Masuk (Rp)',
        'Keluar (Rp)',
        'Saldo (Rp)',
      ],
      data: rows,
      headerStyle: pw.TextStyle(
          fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _emerald),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      oddRowDecoration: pw.BoxDecoration(color: _zebra),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.4),
        bottom: pw.BorderSide(color: _line, width: 0.4),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FixedColumnWidth(56),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1.7),
        5: const pw.FlexColumnWidth(1.7),
        6: const pw.FlexColumnWidth(1.9),
      },
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      headerAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
    );
  }
}
