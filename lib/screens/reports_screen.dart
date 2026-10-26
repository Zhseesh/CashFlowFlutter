import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/cashflow_repository.dart';
import '../services/csv_export_service.dart';
import '../services/json_backup_service.dart';
import '../services/pdf_export_service.dart';
import '../utils/app_events.dart';
import '../utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = CashFlowRepository();
  bool _busy = false;
  double _saldoAwal = 0;

  @override
  void initState() {
    super.initState();
    _loadSaldo();
  }

  Future<void> _loadSaldo() async {
    final s = await _repo.getSaldoAwal();
    if (mounted) setState(() => _saldoAwal = s);
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      _toast('Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFile(File file, String mime) async {
    await Share.shareXFiles([XFile(file.path, mimeType: mime)], text: 'Cash Flow Export');
    _toast('Berkas siap: ${file.path.split('/').last}');
  }

  Future<void> _exportPdf() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final txs = await _repo.getTransactions(from: start, to: end, limit: 10000);
    final inc = await _repo.totalByType('INCOME', from: start, to: end);
    final exp = await _repo.totalByType('EXPENSE', from: start, to: end);
    final monthly = await _repo.monthlyTotals(now.year);
    final file = await PdfExportService.buildReport(
      transactions: txs,
      saldoAwal: _saldoAwal,
      totalIncome: inc,
      totalExpense: exp,
      periodStart: start,
      periodEnd: end,
      monthlyData: monthly,
      year: now.year,
    );
    await _shareFile(file, 'application/pdf');
  }

  Future<void> _exportCsv() async {
    final all = await _repo.getTransactions(limit: 100000);
    final file = await CsvExportService.export(transactions: all, saldoAwal: _saldoAwal);
    await _shareFile(file, 'text/csv');
  }

  Future<void> _backupJson() async {
    final cats = await _repo.getCategories();
    final txs = await _repo.getTransactions(limit: 100000);
    final file = await JsonBackupService.export(
        categories: cats, transactions: txs, saldoAwal: _saldoAwal);
    await _shareFile(file, 'application/json');
  }

  Future<void> _importJson() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
    if (res == null || res.files.single.path == null) return;
    final raw = await File(res.files.single.path!).readAsString();
    final parsed = await JsonBackupService.parse(raw);
    if (!mounted) return;
    final mode = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Impor Cadangan'),
        content: Text('Ditemukan ${parsed.transactions.length} transaksi. Pilih mode impor:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          OutlinedButton(onPressed: () => Navigator.pop(context, 'append'), child: const Text('Tumpuk')),
          FilledButton(onPressed: () => Navigator.pop(context, 'replace'), child: const Text('Ganti Semua')),
        ],
      ),
    );
    if (mode == null) return;
    if (mode == 'replace') {
      final all = await _repo.getTransactions(limit: 1000000);
      for (final t in all) {
        if (t.id != null) await _repo.deleteTransaction(t.id!);
      }
    }
    await _repo.restoreTransactions(parsed.transactions);
    await _repo.setSaldoAwal(parsed.saldoAwal);
    AppEvents.notify();
    await _loadSaldo();
    _toast('Impor berhasil: ${parsed.transactions.length} transaksi');
  }

  Future<void> _editSaldo() async {
    final ctrl = TextEditingController(text: _saldoAwal.toStringAsFixed(0));
    final res = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Saldo Awal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text) ?? 0),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (res != null) {
      await _repo.setSaldoAwal(res);
      await _loadSaldo();
      AppEvents.notify();
      _toast('Saldo awal diperbarui');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan & Data', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: const Text('Saldo Awal'),
                subtitle: Text(formatCurrency(_saldoAwal)),
                trailing: const Icon(Icons.edit),
                onTap: _editSaldo,
              ),
            ),
            const SizedBox(height: 12),
            _section('Ekspor Dokumen'),
            _item(Icons.picture_as_pdf, 'Ekspor PDF Bulanan',
                'Laporan lengkap dengan grafik & mutasi', _exportPdf),
            _item(Icons.table_chart, 'Ekspor CSV',
                'Spreadsheet siap Excel/Sheets', _exportCsv),
            const SizedBox(height: 12),
            _section('Cadangan Data'),
            _item(Icons.backup, 'Cadangkan (JSON)',
                'Simpan & bagikan seluruh data', _backupJson),
            _item(Icons.restore, 'Pulihkan (JSON)',
                'Impor dari berkas cadangan', _importJson),
          ],
        ),
        if (_busy)
          Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
      ]),
    );
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(s,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
      );

  Widget _item(IconData icon, String title, String sub, Future<void> Function() onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _run(onTap),
      ),
    );
  }
}