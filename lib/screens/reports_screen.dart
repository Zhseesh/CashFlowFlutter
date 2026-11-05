import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../services/attachment_service.dart';
import '../services/csv_export_service.dart';
import '../services/json_backup_service.dart';
import '../services/pdf_export_service.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = CashFlowRepository();
  bool _busy = false;

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
    int selectedMonth = now.month;
    int selectedYear = now.year;

    final result = await showDialog<({int month, int year})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Periode Laporan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PERBAIKAN: Menggunakan initialValue
              DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                decoration: const InputDecoration(labelText: 'Bulan'),
                items: List.generate(12, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(2024, i + 1, 1))),
                )),
                onChanged: (v) => selectedMonth = v!,
              ),
              const SizedBox(height: 12),
              // PERBAIKAN: Menggunakan initialValue
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                decoration: const InputDecoration(labelText: 'Tahun'),
                items: List.generate(10, (i) => DropdownMenuItem(
                  value: now.year - i,
                  child: Text('${now.year - i}'),
                )),
                onChanged: (v) => selectedYear = v!,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(context, (month: selectedMonth, year: selectedYear)),
              child: const Text('Ekspor'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final start = DateTime(result.year, result.month, 1);
    final end = DateTime(result.year, result.month + 1, 0, 23, 59, 59);
    
    final txs = await _repo.getTransactions(walletId: walletId, from: start, to: end, limit: 10000);
    final inc = await _repo.totalByType('INCOME', walletId: walletId, from: start, to: end);
    final exp = await _repo.totalByType('EXPENSE', walletId: walletId, from: start, to: end);
    final monthly = await _repo.monthlyTotals(result.year, walletId: walletId);
    
    final file = await PdfExportService.buildReport(
      walletName: walletName, transactions: txs, 
      saldoAwal: 0, 
      totalIncome: inc, totalExpense: exp, periodStart: start, periodEnd: end,
      monthlyData: monthly, year: result.year,
    );

    if (file == null) return _toast('Gagal membuat PDF.');
    
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Laporan PDF',
      fileName: fileName,
      bytes: bytes,
    );

    // PERBAIKAN: Guard mounted sebelum akses context
    if (outputFile != null) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.translate('saved_success'));
    }
  }

  Future<void> _exportCsv() async {
    final walletId = AppState.activeWalletId;
    final walletName = AppState.activeWallet.value?.name ?? 'Utama';
    if (walletId == null) return;
    
    final all = await _repo.getTransactions(walletId: walletId, limit: 100000);
    final file = await CsvExportService.export(
      walletName: walletName, transactions: all, 
      saldoAwal: 0, 
    );
    
    if (file == null) return _toast('Gagal membuat CSV.');

    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Data CSV',
      fileName: fileName,
      bytes: bytes,
    );

    // PERBAIKAN: Guard mounted sebelum akses context
    if (outputFile != null) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.translate('saved_success'));
    }
  }

  Future<void> _backupJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final cats = await _repo.getCategories();
    final txs = await _repo.getTransactions(walletId: walletId, limit: 100000);
    
    final jsonString = await JsonBackupService.export(
      categories: cats, transactions: txs, 
      saldoAwal: 0, 
    );
    
    final fileName = 'CashFlow_Backup_${DateTime.now().millisecondsSinceEpoch}.json';
    
    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Cadangan JSON',
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(jsonString)),
    );

    // PERBAIKAN: Guard mounted sebelum akses context
    if (outputFile != null) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.translate('saved_success'));
    }
  }

  Future<void> _importJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.translate('import_confirm')),
        content: Text('${l10n.translate('import_msg')} (${parsed.transactions.length} transaksi)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('cancel'))),
          OutlinedButton(onPressed: () => Navigator.pop(context, 'append'), child: Text(l10n.translate('append'))),
          FilledButton(onPressed: () => Navigator.pop(context, 'replace'), child: Text(l10n.translate('replace'))),
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
          type: pt.transaction.type == 'INCOME' ? 'INCOME' : 'EXPENSE', 
          categoryId: pt.transaction.categoryId, categoryName: pt.transaction.categoryName,
          dateMillis: pt.transaction.dateMillis, note: pt.transaction.note,
          attachments: newFilenames,
        );
        finalTxs.add(updatedTx);
      }
      
      await _repo.restoreTransactions(finalTxs, walletId: walletId);
      await _repo.setSaldoAwal(walletId, parsed.saldoAwal);
      
      AppEvents.notify();
      _toast('${l10n.translate('import_success')}: ${parsed.transactions.length}');
    } catch (e) {
      _toast('Gagal impor: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text(l10n.translate('reports_data'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              ValueListenableBuilder(
                valueListenable: AppState.activeWallet,
                builder: (context, wallet, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 24), 
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
                          '${l10n.translate('report_for')} ',
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

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(l10n.translate('export_document').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500)),
              ),
              Material(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildFlushItem(
                      icon: Icons.picture_as_pdf,
                      title: l10n.translate('export_pdf'),
                      subtitle: l10n.translate('export_pdf_sub'),
                      onTap: _exportPdf,
                      isDark: isDark,
                      showDivider: true,
                    ),
                    _buildFlushItem(
                      icon: Icons.table_chart,
                      title: l10n.translate('export_csv'),
                      subtitle: l10n.translate('export_csv_sub'),
                      onTap: _exportCsv,
                      isDark: isDark,
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(l10n.translate('backup_data').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500)),
              ),
              Material(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildFlushItem(
                      icon: Icons.cloud_upload_outlined,
                      title: l10n.translate('backup_json'),
                      subtitle: l10n.translate('backup_json_sub'),
                      onTap: _backupJson,
                      isDark: isDark,
                      showDivider: true,
                    ),
                    _buildFlushItem(
                      icon: Icons.restore,
                      title: l10n.translate('restore_json'),
                      subtitle: l10n.translate('restore_json_sub'),
                      onTap: _importJson,
                      isDark: isDark,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 120),
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