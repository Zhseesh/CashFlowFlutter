import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
      walletName: walletName, transactions: txs, saldoAwal: _saldoAwal,
      totalIncome: inc, totalExpense: exp, periodStart: start, periodEnd: end,
      monthlyData: monthly, year: now.year,
    );

    if (file == null) return _toast('Gagal membuat PDF.');
    
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Laporan PDF',
      fileName: fileName,
      bytes: bytes,
    );

    if (outputFile != null) _toast('Berhasil disimpan!');
  }

  Future<void> _exportCsv() async {
    final walletId = AppState.activeWalletId;
    final walletName = AppState.activeWallet.value?.name ?? 'Utama';
    if (walletId == null) return;
    
    final all = await _repo.getTransactions(walletId: walletId, limit: 100000);
    final file = await CsvExportService.export(walletName: walletName, transactions: all, saldoAwal: _saldoAwal);
    
    if (file == null) return _toast('Gagal membuat CSV.');

    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Data CSV',
      fileName: fileName,
      bytes: bytes,
    );

    if (outputFile != null) _toast('Berhasil disimpan!');
  }

  Future<void> _backupJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final cats = await _repo.getCategories();
    final txs = await _repo.getTransactions(walletId: walletId, limit: 100000);
    
    final jsonString = await JsonBackupService.export(categories: cats, transactions: txs, saldoAwal: _saldoAwal);
    
    final fileName = 'CashFlow_Backup_${DateTime.now().millisecondsSinceEpoch}.json';
    
    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Cadangan JSON',
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(jsonString)),
    );

    if (outputFile != null) _toast('Berhasil disimpan!');
  }

  Future<void> _importJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
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
        final newFilenames = <String>[];
        
        for (final b64Data in pt.attachmentBases64) {
           final parts = b64Data.split('|');
           if (parts.length == 2) {
              final newFilename = await AttachmentService.saveFromBase64(parts[0], parts[1]);
              newFilenames.add(newFilename);
           }
        }
        
        final updatedTx = TransactionRecord(
          id: null, walletId: walletId, title: pt.transaction.title, amount: pt.transaction.amount,
          type: pt.transaction.type, categoryId: pt.transaction.categoryId, categoryName: pt.transaction.categoryName,
          dateMillis: pt.transaction.dateMillis, note: pt.transaction.note,
          attachments: newFilenames,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              const Text('Laporan & Data', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Active Wallet Info
              ValueListenableBuilder(
                valueListenable: AppState.activeWallet,
                builder: (context, wallet, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_box_outlined, size: 20, color: Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        Text(
                          'Laporan untuk: ',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        ),
                        Text(
                          wallet?.name ?? "-",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Initial Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.savings_outlined, size: 20, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saldo Awal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(formatCurrency(_saldoAwal), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                      onPressed: _editSaldo,
                    ),
                  ],
                ),
              ),

              // Section: Ekspor
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('EKSPOR DOKUMEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500)),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _buildFlushItem(
                        icon: Icons.picture_as_pdf,
                        title: 'Ekspor PDF Bulanan',
                        subtitle: 'Laporan lengkap dengan grafik & mutasi',
                        onTap: _exportPdf,
                        isDark: isDark,
                        showDivider: true,
                      ),
                      _buildFlushItem(
                        icon: Icons.table_chart,
                        title: 'Ekspor CSV',
                        subtitle: 'Spreadsheet siap Excel/Sheets',
                        onTap: _exportCsv,
                        isDark: isDark,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),

              // Section: Backup
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text('CADANGAN DATA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _buildFlushItem(
                        icon: Icons.cloud_upload_outlined,
                        title: 'Cadangkan (JSON)',
                        subtitle: 'Simpan & bagikan seluruh data',
                        onTap: _backupJson,
                        isDark: isDark,
                        showDivider: true,
                      ),
                      _buildFlushItem(
                        icon: Icons.restore,
                        title: 'Pulihkan (JSON)',
                        subtitle: 'Impor dari berkas cadangan',
                        onTap: _importJson,
                        isDark: isDark,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_busy)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ]),
      ),
    );
  }

  Widget _buildFlushItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required bool showDivider,
  }) {
    return InkWell(
      onTap: () => _run(() async => onTap()),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider 
              ? Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)) 
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Icon(icon, size: 22, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}