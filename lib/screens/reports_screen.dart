import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/cashflow_repository.dart';
import '../models/transaction.dart';
import '../services/attachment_service.dart';
import '../services/csv_export_service.dart';
import '../services/json_backup_service.dart';
import '../services/pdf_export_service.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
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
    AppState.activeWallet.addListener(_loadSaldo);
    _loadSaldo();
  }

  @override
  void dispose() {
    AppState.activeWallet.removeListener(_loadSaldo);
    super.dispose();
  }

  Future<void> _loadSaldo() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;
    final s = await _repo.getSaldoAwal(walletId);
    if (mounted) setState(() => _saldoAwal = s);
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

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
    final displayPath = file.path.replaceFirst('/storage/emulated/0/', '');
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tersimpan di:\n$displayPath'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Bagikan',
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path, mimeType: mime)],
                text: 'Cash Flow Export',
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final walletId = AppState.activeWalletId;
    final walletName = AppState.activeWallet.value?.name ?? 'Utama';
    if (walletId == null) return;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final txs = await _repo.getTransactions(walletId: walletId, from: start, to: end, limit: 10000);
    final inc = await _repo.totalByType('INCOME', walletId: walletId, from: start, to: end);
    final exp = await _repo.totalByType('EXPENSE', walletId: walletId, from: start, to: end);
    final monthly = await _repo.monthlyTotals(now.year, walletId: walletId);
    
    final file = await PdfExportService.buildReport(
      walletName: walletName,
      transactions: txs,
      saldoAwal: _saldoAwal,
      totalIncome: inc,
      totalExpense: exp,
      periodStart: start,
      periodEnd: end,
      monthlyData: monthly,
      year: now.year,
    );
    if (file == null) {
      _toast('Gagal menyimpan PDF.');
      return;
    }
    await _shareFile(file, 'application/pdf');
  }

  Future<void> _exportCsv() async {
    final walletId = AppState.activeWalletId;
    final walletName = AppState.activeWallet.value?.name ?? 'Utama';
    if (walletId == null) return;
    
    final all = await _repo.getTransactions(walletId: walletId, limit: 100000);
    final file = await CsvExportService.export(
      walletName: walletName,
      transactions: all, 
      saldoAwal: _saldoAwal,
    );
    if (file == null) {
      _toast('Gagal menyimpan CSV.');
      return;
    }
    await _shareFile(file, 'text/csv');
  }

  Future<void> _backupJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final cats = await _repo.getCategories();
    final txs = await _repo.getTransactions(walletId: walletId, limit: 100000);
    final file = await JsonBackupService.export(
        categories: cats, transactions: txs, saldoAwal: _saldoAwal);
    
    if (file == null) {
      _toast('Gagal menyimpan JSON.');
      return;
    }
    await _shareFile(file, 'application/json');
  }

  Future<void> _importJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final res = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
    if (res.isEmpty) return;
    
    final path = res.first.path;
    if (path == null) return;
    
    final raw = await File(path).readAsString();
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

    setState(() => _busy = true);
    try {
      if (mode == 'replace') {
        final all = await _repo.getTransactions(walletId: walletId, limit: 1000000);
        for (final t in all) {
          if (t.id != null) await _repo.deleteTransaction(t.id!);
        }
      }
      
      final finalTxs = <TransactionRecord>[];
      for (final pt in parsed.transactions) {
        String? newFilename;
        
        if (pt.attachmentBase64 != null) {
          final parts = pt.attachmentBase64!.split('|');
          if (parts.length == 2) {
            newFilename = await AttachmentService.saveFromBase64(parts[0], parts[1]);
          }
        }
        
        final updatedTx = TransactionRecord(
          id: null,
          walletId: walletId,
          title: pt.transaction.title,
          amount: pt.transaction.amount,
          type: pt.transaction.type,
          categoryId: pt.transaction.categoryId,
          categoryName: pt.transaction.categoryName,
          dateMillis: pt.transaction.dateMillis,
          note: pt.transaction.note,
          attachmentPath: newFilename,
        );
        finalTxs.add(updatedTx);
      }
      
      await _repo.restoreTransactions(finalTxs, walletId: walletId);
      await _repo.setSaldoAwal(walletId, parsed.saldoAwal);
      
      AppEvents.notify();
      await _loadSaldo();
      _toast('Impor berhasil: ${parsed.transactions.length} transaksi');
    } catch (e) {
      _toast('Gagal impor: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editSaldo() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

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
      await _repo.setSaldoAwal(walletId, res);
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
            ValueListenableBuilder(
              valueListenable: AppState.activeWallet,
              builder: (context, wallet, _) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder_shared_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Laporan untuk: ${wallet?.name ?? "-"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
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