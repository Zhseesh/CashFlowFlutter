import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../services/attachment_service.dart';
import '../services/csv_export_service.dart';
import '../services/json_backup_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/neo_theme.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/neo_dropdown.dart';
import '../widgets/neo_toast.dart';

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
    // Menggunakan NeoToast yang muncul melayang di atas navbar
    NeoToast.show(context, m);
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

  // ── EXPORT PDF ─────────────────────────────────────────
  Future<void> _exportPdf() async {
    final walletId = AppState.activeWalletId;
    final walletName = AppState.activeWallet.value?.name ?? 'Utama';
    if (walletId == null) return;

    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    final result = await showNeoDialog<({int month, int year})>(
      context: context,
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeoDialogTitle('Pilih Periode Laporan'),
              NeoDropdown<int>(
                label: 'Bulan',
                value: selectedMonth,
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      DateFormat('MMMM', 'id_ID')
                          .format(DateTime(2024, i + 1, 1)),
                    ),
                  ),
                ),
                onChanged: (v) => setLocal(() => selectedMonth = v!),
              ),
              const SizedBox(height: 12),
              NeoDropdown<int>(
                label: 'Tahun',
                value: selectedYear,
                items: List.generate(
                  10,
                  (i) => DropdownMenuItem(
                    value: now.year - i,
                    child: Text('${now.year - i}'),
                  ),
                ),
                onChanged: (v) => setLocal(() => selectedYear = v!),
              ),
              NeoDialogActions(
                children: [
                  NeoButton(
                    label: 'Batal',
                    variant: NeoButtonVariant.secondary,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  NeoButton(
                    label: 'Ekspor',
                    icon: LucideIcons.download,
                    onPressed: () => Navigator.pop(
                      ctx,
                      (month: selectedMonth, year: selectedYear),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;

    final start = DateTime(result.year, result.month, 1);
    final end = DateTime(result.year, result.month + 1, 0, 23, 59, 59);

    final txs = await _repo.getTransactions(
        walletId: walletId, from: start, to: end, limit: 10000);
    final inc = await _repo.totalByType('INCOME',
        walletId: walletId, from: start, to: end);
    final exp = await _repo.totalByType('EXPENSE',
        walletId: walletId, from: start, to: end);
    final monthly = await _repo.monthlyTotals(result.year,
        walletId: walletId);

    final file = await PdfExportService.buildReport(
      walletName: walletName,
      transactions: txs,
      saldoAwal: 0,
      totalIncome: inc,
      totalExpense: exp,
      periodStart: start,
      periodEnd: end,
      monthlyData: monthly,
      year: result.year,
    );

    if (file == null) return _toast('Gagal membuat PDF.');

    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Laporan PDF',
      fileName: fileName,
      bytes: bytes,
    );

    if (outputFile != null) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.translate('saved_success'));
    }
  }

  // ── EXPORT CSV ─────────────────────────────────────────
  Future<void> _exportCsv() async {
    final walletId = AppState.activeWalletId;
    final walletName = AppState.activeWallet.value?.name ?? 'Utama';
    if (walletId == null) return;

    final all = await _repo.getTransactions(walletId: walletId, limit: 100000);
    final file = await CsvExportService.export(
      walletName: walletName,
      transactions: all,
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

    if (outputFile != null) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.translate('saved_success'));
    }
  }

  // ── BACKUP JSON ────────────────────────────────────────
  Future<void> _backupJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final cats = await _repo.getCategories();
    final txs =
        await _repo.getTransactions(walletId: walletId, limit: 100000);

    final jsonString = await JsonBackupService.export(
      categories: cats,
      transactions: txs,
      saldoAwal: 0,
    );

    final fileName =
        'CashFlow_Backup_${DateTime.now().millisecondsSinceEpoch}.json';

    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan Cadangan JSON',
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(jsonString)),
    );

    if (outputFile != null) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context)!.translate('saved_success'));
    }
  }

  // ── IMPORT JSON ────────────────────────────────────────
  Future<void> _importJson() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    final l10n = AppLocalizations.of(context)!;
    final res = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
    if (res.isEmpty) return;
    final path = res.first.path;
    if (path == null) return;

    final raw = await File(path).readAsString();
    final parsed = await JsonBackupService.parse(raw);
    if (!mounted) return;

    final mode = await showNeoDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoDialogTitle(l10n.translate('import_confirm')),
          Text(
            '${l10n.translate('import_msg')} (${parsed.transactions.length} transaksi)',
            style: NeoText.body(13, color: Neo.ink(context)),
          ),
          NeoDialogActions(
            children: [
              NeoButton(
                label: l10n.translate('cancel'),
                variant: NeoButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
              NeoButton(
                label: l10n.translate('append'),
                variant: NeoButtonVariant.ghost,
                onPressed: () => Navigator.pop(context, 'append'),
              ),
              NeoButton(
                label: l10n.translate('replace'),
                onPressed: () => Navigator.pop(context, 'replace'),
              ),
            ],
          ),
        ],
      ),
    );
    if (mode == null) return;

    setState(() => _busy = true);
    try {
      if (mode == 'replace') {
        final all = await _repo.getTransactions(
            walletId: walletId, limit: 1000000);
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
            final newFilename =
                await AttachmentService.saveFromBase64(parts[0], parts[1]);
            newFilenames.add(newFilename);
          }
        }

        final updatedTx = TransactionRecord(
          id: null,
          walletId: walletId,
          title: pt.transaction.title,
          amount: pt.transaction.amount,
          type: pt.transaction.type == 'INCOME' ? 'INCOME' : 'EXPENSE',
          categoryId: pt.transaction.categoryId,
          categoryName: pt.transaction.categoryName,
          dateMillis: pt.transaction.dateMillis,
          note: pt.transaction.note,
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

  // ── BUILD ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text(
                l10n.translate('reports_data').toUpperCase(),
                style: NeoText.display(22, color: ink),
              ),
              const SizedBox(height: 20),

              // ── WALLET INFO ──────────────────────────────
              ValueListenableBuilder(
                valueListenable: AppState.activeWallet,
                builder: (context, wallet, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: NeoColors.lime,
                      borderRadius: BorderRadius.circular(NeoRadius.reg),
                      border: NeoBorders.reg(ink),
                      boxShadow: NeoShadows.sm(ink),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.user,
                            size: 20, color: NeoColors.inkLight),
                        const SizedBox(width: 10),
                        Text(
                          l10n.translate('report_for').toUpperCase(),
                          style: NeoText.label(10,
                              color: NeoColors.inkLight),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            wallet?.name ?? '-',
                            style: NeoText.body(13,
                                weight: FontWeight.w700,
                                color: NeoColors.inkLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── EXPORT SECTION ───────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.translate('export_document').toUpperCase(),
                  style: NeoText.label(10, color: ink),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Neo.paper(context),
                  borderRadius: BorderRadius.circular(NeoRadius.lg),
                  border: NeoBorders.reg(ink),
                  boxShadow: NeoShadows.sm(ink),
                ),
                child: Column(
                  children: [
                    _buildFlushItem(
                      icon: LucideIcons.fileText,
                      iconBg: NeoColors.cyan,
                      title: l10n.translate('export_pdf'),
                      subtitle: l10n.translate('export_pdf_sub'),
                      onTap: _exportPdf,
                      ink: ink,
                      showDivider: true,
                    ),
                    _buildFlushItem(
                      icon: LucideIcons.table,
                      iconBg: NeoColors.yellow,
                      title: l10n.translate('export_csv'),
                      subtitle: l10n.translate('export_csv_sub'),
                      onTap: _exportCsv,
                      ink: ink,
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── BACKUP SECTION ───────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.translate('backup_data').toUpperCase(),
                  style: NeoText.label(10, color: ink),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Neo.paper(context),
                  borderRadius: BorderRadius.circular(NeoRadius.lg),
                  border: NeoBorders.reg(ink),
                  boxShadow: NeoShadows.sm(ink),
                ),
                child: Column(
                  children: [
                    _buildFlushItem(
                      icon: LucideIcons.cloudUpload,
                      iconBg: NeoColors.purple,
                      title: l10n.translate('backup_json'),
                      subtitle: l10n.translate('backup_json_sub'),
                      onTap: _backupJson,
                      ink: ink,
                      showDivider: true,
                    ),
                    _buildFlushItem(
                      icon: LucideIcons.rotateCcw,
                      iconBg: NeoColors.pink,
                      title: l10n.translate('restore_json'),
                      subtitle: l10n.translate('restore_json_sub'),
                      onTap: _importJson,
                      ink: ink,
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),

          // ── BUSY OVERLAY ─────────────────────────────
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Neo.paper(context),
                    borderRadius: BorderRadius.circular(NeoRadius.lg),
                    border: NeoBorders.thick(ink),
                    boxShadow: NeoShadows.md(ink),
                  ),
                  child: CircularProgressIndicator(
                    color: NeoColors.yellow,
                    backgroundColor: ink.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── FLUSH MENU ITEM ────────────────────────────────────
  Widget _buildFlushItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color ink,
    required bool showDivider,
  }) {
    return GestureDetector(
      onTap: () => _run(() async => onTap()),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: ink, width: 2))
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                border: NeoBorders.thin(ink),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: NeoColors.inkLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NeoText.body(13,
                        weight: FontWeight.w700, color: ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: NeoText.label(9,
                        color: ink.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: ink.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}