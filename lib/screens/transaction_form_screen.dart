import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import '../data/cashflow_repository.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/attachment_service.dart';
import '../utils/app_events.dart';
import '../utils/formatters.dart';
import '../utils/app_state.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionRecord? editing;
  const TransactionFormScreen({super.key, this.editing});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CashFlowRepository();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'EXPENSE';
  Category? _category;
  DateTime _date = DateTime.now();
  List<Category> _categories = [];
  bool _saving = false;

  // Attachment state
  String? _existingFilename;   // dari DB (mode edit)
  String? _pickedTempPath;     // file sementara baru dipilih
  String? _pickedDisplayName;  // nama asli file yang baru dipilih
  bool _removeExisting = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.editing!;
      _titleCtrl.text = e.title;
      _amountCtrl.text =
          NumberFormat.decimalPattern('id_ID').format(e.amount.round());
      _noteCtrl.text = e.note ?? '';
      _type = e.type;
      _date = e.date;
      _existingFilename = e.attachmentPath;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final list = await _repo.getCategories(type: _type);
    if (!mounted) return;
    setState(() {
      _categories = list;
      if (list.isEmpty) {
        _category = null;
      } else {
        _category = list.firstWhere(
          (c) => c.name == widget.editing?.categoryName,
          orElse: () => list.first,
        );
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAttachment() async {
    try {
      final res = await AttachmentService.pick();
      if (res == null) return;
      setState(() {
        _pickedTempPath = res.path;
        _pickedDisplayName = res.name;
        _removeExisting = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e')),
      );
    }
  }

  void _removeAttachment() {
    setState(() {
      if (_pickedTempPath != null) {
        _pickedTempPath = null;
        _pickedDisplayName = null;
      } else if (_existingFilename != null) {
        _removeExisting = true;
      }
    });
  }

  Future<void> _viewAttachment() async {
    try {
      if (_pickedTempPath != null) {
        final result = await OpenFilex.open(_pickedTempPath!);
        if (result.type != ResultType.done) throw Exception(result.message);
      } else if (_existingFilename != null) {
        await AttachmentService.open(_existingFilename!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka file: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    setState(() => _saving = true);
    try {
      // 1. Resolve attachment final
      String? finalAttachment;
      if (_pickedTempPath != null) {
        // Ada file baru → copy ke permanen
        finalAttachment =
            await AttachmentService.copyToPermanent(_pickedTempPath!);
        // Hapus file lama jika ada
        if (_existingFilename != null) {
          await AttachmentService.delete(_existingFilename);
        }
      } else if (_removeExisting) {
        // User hapus tanpa ganti
        await AttachmentService.delete(_existingFilename);
        finalAttachment = null;
      } else {
        // Tidak berubah
        finalAttachment = _existingFilename;
      }

      // 2. Simpan transaksi
      final amount = double.parse(
          _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
      final t = TransactionRecord(
        id: widget.editing?.id,
        walletId: widget.editing?.walletId ?? AppState.activeWalletId, // <-- TAMBAHKAN INI
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        categoryId: _category!.id,
        categoryName: _category!.name,
        dateMillis: _date.millisecondsSinceEpoch,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        attachmentPath: finalAttachment,
      );

      if (_isEditing) {
        await _repo.updateTransaction(t);
      } else {
        await _repo.insertTransaction(t);
      }

      AppEvents.notify();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  Future<void> _delete() async {
    final id = widget.editing?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text('"${widget.editing!.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _repo.deleteTransaction(id);
      await AttachmentService.delete(_existingFilename);
      AppEvents.notify();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }

  Widget _buildAttachmentSection() {
    // Tentukan apa yang ditampilkan
    String? label;
    String? sublabel;
    bool isPending = false;

    if (_pickedTempPath != null) {
      label = _pickedDisplayName ?? 'File baru';
      sublabel = 'Akan disimpan saat Anda tekan ${_isEditing ? "Perbarui" : "Simpan"}';
      isPending = true;
    } else if (_existingFilename != null && !_removeExisting) {
      final ext = p
          .extension(_existingFilename!)
          .replaceAll('.', '')
          .toLowerCase();
      label = ext == 'pdf' ? 'Dokumen PDF' : 'Gambar';
      sublabel = 'Bukti transfer terlampir';
    }

    if (label == null) {
      return OutlinedButton.icon(
        onPressed: _saving ? null : _pickAttachment,
        icon: const Icon(Icons.attach_file),
        label: const Text('Tambah Bukti Transfer'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    final color =
        _type == 'INCOME' ? const Color(0xFF10B981) : const Color(0xFFE11D48);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isPending ? Icons.cloud_upload : Icons.attach_file,
              color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (!isPending)
            IconButton(
              tooltip: 'Lihat',
              icon: const Icon(Icons.visibility_outlined, size: 20),
              onPressed: _saving ? null : _viewAttachment,
            ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.close, size: 20),
            onPressed: _saving ? null : _removeAttachment,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor =
        _type == 'INCOME' ? const Color(0xFF10B981) : const Color(0xFFE11D48);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Transaksi' : 'Transaksi Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFE11D48)),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'INCOME',
                    label: Text('Pemasukan'),
                    icon: Icon(Icons.south_west)),
                ButtonSegment(
                    value: 'EXPENSE',
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.north_east)),
              ],
              selected: {_type},
              onSelectionChanged: _saving
                  ? null
                  : (s) {
                      setState(() {
                        _type = s.first;
                        _category = null;
                      });
                      _loadCategories();
                    },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Contoh: Gaji bulanan',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                final n = double.tryParse(v.replaceAll('.', ''));
                if (n == null || n <= 0) return 'Nominal tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged:
                  _saving ? null : (c) => setState(() => _category = c),
              validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _saving ? null : _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Bukti Transfer',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildAttachmentSection(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Perbarui' : 'Simpan',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted =
        NumberFormat.decimalPattern('id_ID').format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}