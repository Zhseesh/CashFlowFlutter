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
import '../utils/app_state.dart';
import '../utils/formatters.dart';

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

  List<String> _existingAttachments = []; 
  final List<String> _newTempAttachments = [];  
  final List<String> _deletedAttachments = []; 

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.editing!;
      _titleCtrl.text = e.title;
      _amountCtrl.text = NumberFormat.decimalPattern('id_ID').format(e.amount.round());
      _noteCtrl.text = e.note ?? '';
      _type = e.type;
      _date = e.date;
      _existingAttachments = List.from(e.attachments);
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
        _newTempAttachments.add(res.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _removeExisting(String path) {
    setState(() {
      _existingAttachments.remove(path);
      _deletedAttachments.add(path);
    });
  }

  void _removeNewTemp(String path) {
    setState(() {
      _newTempAttachments.remove(path);
    });
  }

  Future<void> _viewFile(String path, {bool isTemp = false}) async {
    try {
      if (isTemp) {
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done) throw Exception(result.message);
      } else {
        await AttachmentService.open(path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal buka: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    setState(() => _saving = true);
    try {
      for (final oldFile in _deletedAttachments) {
        await AttachmentService.delete(oldFile);
      }

      final finalAttachments = List<String>.from(_existingAttachments);
      for (final tempPath in _newTempAttachments) {
        final newFilename = await AttachmentService.copyToPermanent(tempPath);
        finalAttachments.add(newFilename);
      }

      final amount = double.parse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
      final t = TransactionRecord(
        id: widget.editing?.id,
        walletId: widget.editing?.walletId ?? AppState.activeWalletId,
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        categoryId: _category!.id,
        categoryName: _category!.name,
        dateMillis: _date.millisecondsSinceEpoch,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        attachments: finalAttachments, 
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)), 
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus')
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _repo.deleteTransaction(id);
      for (final file in widget.editing!.attachments) {
        await AttachmentService.delete(file); 
      }
      AppEvents.notify();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }

  Widget _buildHairlineInput({
    required IconData icon,
    required String label,
    required Widget child,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Icon(icon, color: iconColor ?? (isDark ? Colors.grey.shade500 : Colors.grey.shade400), size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUKTI TRANSFER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),

        // List File Lama
        ..._existingAttachments.map((path) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.attach_file, color: Color(0xFF10B981), size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Lampiran tersimpan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF059669))),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                onPressed: () => _viewFile(path),
                color: Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeExisting(path),
                color: Colors.grey,
              ),
            ],
          ),
        )),

        // List File Baru
        ..._newTempAttachments.map((path) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_upload, color: Colors.orange, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.basename(path), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    const Text('Belum disimpan', style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                onPressed: () => _viewFile(path, isTemp: true),
                color: Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeNewTemp(path),
                color: Colors.grey,
              ),
            ],
          ),
        )),

        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _pickAttachment,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Bukti Transfer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _type == 'INCOME' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Transaksi' : 'Transaksi Baru', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // ── ANIMASI SLIDING TOGGLE ──
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
              ),
              child: Stack(
                children: [
                  // 1. Background Geser (AnimatedAlign)
                  AnimatedAlign(
                    alignment: _type == 'INCOME' ? Alignment.centerLeft : Alignment.centerRight,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 2. Teks & Ikon Tombol
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _saving ? null : () { setState(() { _type = 'INCOME'; _category = null; }); _loadCategories(); },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 14, color: _type == 'INCOME' ? const Color(0xFF10B981) : Colors.grey),
                                const SizedBox(width: 6),
                                Text('Pemasukan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _type == 'INCOME' ? const Color(0xFF10B981) : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _saving ? null : () { setState(() { _type = 'EXPENSE'; _category = null; }); _loadCategories(); },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_outward, size: 14, color: _type == 'EXPENSE' ? const Color(0xFFEF4444) : Colors.grey),
                                const SizedBox(width: 6),
                                Text('Pengeluaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _type == 'EXPENSE' ? const Color(0xFFEF4444) : Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── FORM HAIRLINE ──
            _buildHairlineInput(
              icon: Icons.title,
              label: 'Judul',
              child: TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Gaji bulanan',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
            ),

            _buildHairlineInput(
              icon: Icons.attach_money,
              label: 'Nominal',
              iconColor: isDark ? Colors.white : Colors.black87,
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandsFormatter()],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                  final n = double.tryParse(v.replaceAll('.', ''));
                  if (n == null || n <= 0) return 'Nominal tidak valid';
                  return null;
                },
              ),
            ),

            _buildHairlineInput(
              icon: Icons.category_outlined,
              label: 'Kategori',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Category>(
                  value: _category,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                  onChanged: _saving ? null : (c) => setState(() => _category = c),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                ),
              ),
            ),

            _buildHairlineInput(
              icon: Icons.calendar_today,
              label: 'Tanggal',
              child: InkWell(
                onTap: _saving ? null : _pickDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatDate(_date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            _buildHairlineInput(
              icon: Icons.notes,
              label: 'Catatan (opsional)',
              child: TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Tambahkan detail...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 12),
            
            // ── ATTACHMENT ──
            _buildAttachmentSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // ── TOMBOL BAWAH ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6),
          border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Perbarui' : 'Simpan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final formatted = NumberFormat.decimalPattern('id_ID').format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}