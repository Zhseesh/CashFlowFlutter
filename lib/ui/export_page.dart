import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../export/csv_exporter.dart';
import '../export/json_backup.dart';
import '../export/pdf_exporter.dart';
import '../models/models.dart';
import '../state/controller_scope.dart';
import '../utils/format.dart';
import 'widgets/app_card.dart';

class _Period {
  const _Period(this.from, this.toExclusive, this.label);
  final DateTime from;
  final DateTime toExclusive;
  final String label;
}

/// Pusat Ekspor & Cadangan Data: PDF, CSV, backup/restore JSON.
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool _busy = false;
  String _delimiter = ';';

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------------------------------------------ periode

  Future<_Period?> _choosePeriod() async {
    final now = DateTime.now();
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih periode'),
        children: [
          for (final o in const {
            'this': 'Bulan ini',
            'last': 'Bulan lalu',
            'pick': 'Pilih rentang tanggal',
            'all': 'Semua data',
          }.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(o.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(o.value),
              ),
            ),
        ],
      ),
    );
    if (choice == null) return null;

    switch (choice) {
      case 'this':
        return _month(DateTime(now.year, now.month));
      case 'last':
        return _month(DateTime(now.year, now.month - 1));
      case 'all':
        return _Period(DateTime(1900), DateTime(9999), 'Semua periode');
      default:
        if (!mounted) return null;
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDateRange: DateTimeRange(
            start: DateTime(now.year, now.month),
            end: now,
          ),
        );
        if (range == null) return null;
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        return _Period(
          DateTime(range.start.year, range.start.month, range.start.day),
          end.add(const Duration(days: 1)),
          '${Fmt.date(range.start)} - ${Fmt.date(range.end)}',
        );
    }
  }

  _Period _month(DateTime m) {
    final start = DateTime(m.year, m.month);
    return _Period(start, DateTime(m.year, m.month + 1), Fmt.monthYear(start));
  }

  // ----------------------------------------------------------------- ekspor

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } catch (e) {
      _snack('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportPdf() async {
    final period = await _choosePeriod();
    if (period == null) return;
    await _run(() async {
      final repo = ControllerScope.of(context).repo;
      final txs = await repo.transactions(
        from: period.from,
        toExclusive: period.toExclusive,
        ascending: true,
      );
      final opening = await repo.balanceBefore(period.from);
      final bytes = await PdfExporter.build(
        transactions: txs,
        openingBalance: opening,
        periodLabel: period.label,
      );
      await _deliver('Laporan_ArusKas_${Fmt.stamp()}.pdf', bytes,
          'application/pdf');
    });
  }

  Future<void> _exportCsv() async {
    final period = await _choosePeriod();
    if (period == null) return;
    await _run(() async {
      final repo = ControllerScope.of(context).repo;
      final txs = await repo.transactions(
        from: period.from,
        toExclusive: period.toExclusive,
        ascending: true,
      );
      final opening = await repo.balanceBefore(period.from);
      final csv = CsvExporter.build(
        transactions: txs,
        openingBalance: opening,
        delimiter: _delimiter,
      );
      await _deliver('ArusKas_${Fmt.stamp()}.csv',
          Uint8List.fromList(utf8.encode(csv)), 'text/csv');
    });
  }

  Future<void> _backupJson() async {
    await _run(() async {
      final repo = ControllerScope.of(context).repo;
      final data = await repo.exportBackup();
      final json = JsonBackup.encode(data);
      await _deliver('cashflow_backup_${Fmt.stamp()}.json',
          Uint8List.fromList(utf8.encode(json)), 'application/json');
    });
  }

  Future<void> _restoreJson() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;

    BackupData data;
    try {
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) throw const FormatException('Berkas tidak dapat dibaca.');
      data = JsonBackup.parse(utf8.decode(bytes));
    } on FormatException catch (e) {
      _snack('Cadangan ditolak: ${e.message}');
      return;
    }
    if (!mounted) return;

    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan data'),
        content: Text(
          'Cadangan valid: ${data.transactions.length} transaksi dan '
          '${data.categories.length} kategori'
          '${data.exportedAt != null ? '\nDibuat: ${data.exportedAt}' : ''}.\n\n'
          'Gabungkan: menambahkan data ke database saat ini (duplikat dilewati).\n'
          'Ganti semua: menghapus seluruh data saat ini lalu memakai cadangan.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop('replace'),
              child: const Text('Ganti semua')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop('merge'),
              child: const Text('Gabungkan')),
        ],
      ),
    );
    if (mode == null) return;

    if (mode == 'replace') {
      if (!mounted) return;
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ganti seluruh data?'),
          content: const Text(
              'Semua transaksi dan kategori saat ini akan dihapus permanen. '
              'Disarankan membuat cadangan terlebih dahulu.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Ya, ganti')),
          ],
        ),
      );
      if (sure != true) return;
    }

    await _run(() async {
      final r = await ControllerScope.of(context)
          .importBackup(data, replace: mode == 'replace');
      _snack(mode == 'replace'
          ? 'Data diganti: ${r.transactions} transaksi.'
          : 'Digabung: ${r.transactions} transaksi baru, ${r.skipped} dilewati.');
    });
  }

  // ---------------------------------------------------------------- berkas

  Future<File> _persist(String name, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final out = Directory(p.join(dir.path, 'exports'));
    await out.create(recursive: true);
    final f = File(p.join(out.path, name));
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  Future<void> _deliver(String name, Uint8List bytes, String mime) async {
    final file = await _persist(name, bytes);
    if (!mounted) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_rounded),
              title: const Text('Berkas siap'),
              subtitle: Text(name),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Bagikan'),
              onTap: () => Navigator.of(ctx).pop('share'),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_rounded),
              title: const Text('Simpan ke perangkat'),
              onTap: () => Navigator.of(ctx).pop('save'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'share') {
      await Share.shareXFiles([XFile(file.path, mimeType: mime)], subject: name);
    } else if (choice == 'save') {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan berkas',
        fileName: name,
        bytes: bytes,
      );
      _snack(path != null ? 'Berkas disimpan.' : 'Penyimpanan dibatalkan.');
    } else {
      _snack('Berkas tersimpan di folder dokumen aplikasi.');
    }
  }

  // --------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget action({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(30),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        enabled: !_busy,
        onTap: onTap,
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('Data & Laporan',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laporan', style: theme.textTheme.titleMedium),
                action(
                  icon: Icons.picture_as_pdf_rounded,
                  title: 'Ekspor PDF',
                  subtitle: 'Kop, rekap saldo, grafik, dan tabel mutasi',
                  onTap: _exportPdf,
                ),
                action(
                  icon: Icons.table_chart_rounded,
                  title: 'Ekspor CSV',
                  subtitle: 'Siap dibuka di Excel, Sheets, atau LibreOffice',
                  onTap: _exportCsv,
                ),
                const SizedBox(height: 4),
                Text('Pemisah kolom CSV', style: theme.textTheme.labelMedium),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: ';', label: Text('Titik koma (;)')),
                    ButtonSegment(value: ',', label: Text('Koma (,)')),
                  ],
                  selected: {_delimiter},
                  onSelectionChanged: (s) =>
                      setState(() => _delimiter = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cadangan', style: theme.textTheme.titleMedium),
                action(
                  icon: Icons.cloud_upload_rounded,
                  title: 'Cadangkan (Ekspor JSON)',
                  subtitle: 'Simpan seluruh transaksi dan kategori',
                  onTap: _backupJson,
                ),
                action(
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Pulihkan (Impor JSON)',
                  subtitle: 'Validasi cadangan, lalu gabungkan atau ganti data',
                  onTap: _restoreJson,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
