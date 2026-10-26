import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction.dart';
import '../utils/formatters.dart';

class PdfExportService {
  static Future<File> buildReport({
    required List<TransactionRecord> transactions,
    required double saldoAwal,
    required double totalIncome,
    required double totalExpense,
    required DateTime periodStart,
    required DateTime periodEnd,
    required Map<int, ({double income, double expense})> monthlyData,
    required int year,
  }) async {
    final doc = pw.Document();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        _header(periodStart, periodEnd),
        pw.SizedBox(height: 16),
        _summaryCard(saldoAwal, totalIncome, totalExpense, fmt),
        pw.SizedBox(height: 20),
        pw.Text('Grafik Bulanan $year',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _barChart(monthlyData),
        pw.SizedBox(height: 20),
        pw.Text('Rincian Mutasi',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _table(transactions, saldoAwal, fmt),
      ],
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9)),
      ),
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/CashFlow_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static pw.Widget _header(DateTime s, DateTime e) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Laporan Arus Kas',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal800)),
          pw.SizedBox(height: 4),
          pw.Text('Periode: ${formatDate(s)} - ${formatDate(e)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Divider(color: PdfColors.teal700, thickness: 1.2),
        ],
      );

  static pw.Widget _summaryCard(double awal, double inc, double exp, NumberFormat fmt) {
    final sisa = awal + inc - exp;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _sumItem('Saldo Awal', fmt.format(awal), PdfColors.blueGrey700),
          _sumItem('Pemasukan', fmt.format(inc), PdfColors.green700),
          _sumItem('Pengeluaran', fmt.format(exp), PdfColors.red700),
          _sumItem('Sisa Saldo', fmt.format(sisa), PdfColors.teal800),
        ],
      ),
    );
  }

  static pw.Widget _sumItem(String label, String value, PdfColor color) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      );

  static pw.Widget _barChart(Map<int, ({double income, double expense})> data) {
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    double maxVal = 1;
    for (final v in data.values) {
      if (v.income > maxVal) maxVal = v.income;
      if (v.expense > maxVal) maxVal = v.expense;
    }
    const chartHeight = 90.0;
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        children: [
          pw.SizedBox(
            height: chartHeight,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: data.entries.map((e) {
                final iH = (e.value.income / maxVal) * chartHeight;
                final eH = (e.value.expense / maxVal) * chartHeight;
                return pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                        width: 5,
                        height: iH > 1 ? iH : 1,
                        color: PdfColors.green600),
                    pw.SizedBox(width: 1),
                    pw.Container(
                        width: 5,
                        height: eH > 1 ? eH : 1,
                        color: PdfColors.red600),
                  ],
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: data.keys
                .map((m) => pw.Text(months[m - 1],
                    style: const pw.TextStyle(fontSize: 7)))
                .toList(),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _legend(PdfColors.green600, 'Pemasukan'),
              pw.SizedBox(width: 16),
              _legend(PdfColors.red600, 'Pengeluaran'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _legend(PdfColor color, String text) => pw.Row(
        children: [
          pw.Container(width: 8, height: 8, color: color),
          pw.SizedBox(width: 4),
          pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
        ],
      );

  static pw.Widget _table(List<TransactionRecord> list, double saldoAwal, NumberFormat fmt) {
    double running = saldoAwal;
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.teal100),
        children: ['No', 'Tanggal', 'Keterangan', 'Kategori', 'Masuk', 'Keluar', 'Saldo']
            .map((t) => _th(t))
            .toList(),
      ),
    ];
    int no = 1;
    for (final t in list) {
      running += t.isIncome ? t.amount : -t.amount;
      rows.add(pw.TableRow(children: [
        _td(no.toString()),
        _td(formatDate(t.date)),
        _td(t.title),
        _td(t.categoryName),
        _td(t.isIncome ? fmt.format(t.amount) : '-',
            color: t.isIncome ? PdfColors.green700 : null),
        _td(!t.isIncome ? fmt.format(t.amount) : '-',
            color: !t.isIncome ? PdfColors.red700 : null),
        _td(fmt.format(running)),
      ]));
      no++;
    }
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FixedColumnWidth(55),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(55),
        4: const pw.FixedColumnWidth(65),
        5: const pw.FixedColumnWidth(65),
        6: const pw.FixedColumnWidth(70),
      },
      children: rows,
    );
  }

  static pw.Widget _th(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900)),
      );

  static pw.Widget _td(String t, {PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(t, style: pw.TextStyle(fontSize: 8, color: color)),
      );
}