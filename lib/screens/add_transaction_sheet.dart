import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/cashflow_repository.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/app_events.dart';
import '../utils/formatters.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionRecord? editing;
  const AddTransactionSheet({super.key, this.editing});
  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
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

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _titleCtrl.text = widget.editing!.title;
      _amountCtrl.text = widget.editing!.amount.toStringAsFixed(0);
      _noteCtrl.text = widget.editing!.note ?? '';
      _type = widget.editing!.type;
      _date = widget.editing!.date;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await _repo.getCategories(type: _type);
    setState(() {
      _categories = list;
      _category = list.firstWhere(
        (c) => c.name == widget.editing?.categoryName,
        orElse: () => list.isNotEmpty ? list.first : Category.defaults.first,
      );
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    setState(() => _saving = true);
    final amount = double.parse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
    final t = TransactionRecord(
      id: widget.editing?.id,
      title: _titleCtrl.text.trim(),
      amount: amount,
      type: _type,
      categoryId: _category!.id,
      categoryName: _category!.name,
      dateMillis: _date.millisecondsSinceEpoch,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (widget.editing == null) {
      await _repo.insertTransaction(t);
    } else {
      await _repo.updateTransaction(t);
    }
    AppEvents.notify();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(widget.editing == null ? 'Transaksi Baru' : 'Edit Transaksi',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'INCOME', label: Text('Pemasukan'), icon: Icon(Icons.south_west)),
                    ButtonSegment(value: 'EXPENSE', label: Text('Pengeluaran'), icon: Icon(Icons.north_east)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) {
                    setState(() {
                      _type = s.first;
                      _category = null;
                    });
                    _loadCategories();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Judul', hintText: 'Contoh: Gaji bulanan'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandsFormatter()],
                  decoration: const InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp '),
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
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (c) => setState(() => _category = c),
                  validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal', suffixIcon: Icon(Icons.calendar_today)),
                    child: Text(formatDate(_date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _type == 'INCOME' ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.editing == null ? 'Simpan' : 'Perbarui'),
                ),
              ],
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