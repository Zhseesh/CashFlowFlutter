import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/controller_scope.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'category_icons.dart';

/// Bottom sheet untuk mencatat atau mengubah transaksi.
Future<void> showTransactionSheet(
  BuildContext context, {
  CashTransaction? existing,
  TxType initialType = TxType.expense,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TransactionForm(existing: existing, initialType: initialType),
  );
}

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, this.existing, required this.initialType});

  final CashTransaction? existing;
  final TxType initialType;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late TxType _type;
  late final TextEditingController _amount;
  late final TextEditingController _title;
  late final TextEditingController _note;
  late DateTime _date;
  Category? _category;
  bool _categoryInit = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.initialType;
    _amount = TextEditingController(
      text: e == null
          ? ''
          : RupiahInputFormatter.group(e.amount.round().toString()),
    );
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoryInit) {
      _categoryInit = true;
      final e = widget.existing;
      if (e != null) _category = ControllerScope.of(context).categoryFor(e);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
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
    final amount = RupiahInputFormatter.parse(_amount.text);
    if (amount <= 0) {
      setState(() => _error = 'Masukkan nominal lebih dari 0.');
      return;
    }
    final cat = _category;
    if (cat == null) {
      setState(() => _error = 'Pilih kategori terlebih dahulu.');
      return;
    }

    final base = widget.existing?.date ?? DateTime.now();
    final when = DateTime(_date.year, _date.month, _date.day, base.hour, base.minute);
    final title = _title.text.trim();
    final note = _note.text.trim();

    final tx = CashTransaction(
      id: widget.existing?.id,
      title: title.isEmpty ? cat.name : title,
      amount: amount,
      type: _type,
      categoryId: cat.id,
      categoryName: cat.name,
      dateMillis: when.millisecondsSinceEpoch,
      note: note.isEmpty ? null : note,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ControllerScope.of(context).saveTransaction(tx);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final cats = c.categories.where((x) => x.type == _type).toList();
    final accent = _type == TxType.income ? AppColors.income : AppColors.expense;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Catat Transaksi' : 'Ubah Transaksi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TxType>(
                segments: const [
                  ButtonSegment(
                    value: TxType.income,
                    label: Text('Pemasukan'),
                    icon: Icon(Icons.south_west_rounded),
                  ),
                  ButtonSegment(
                    value: TxType.expense,
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.north_east_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  if (_category?.type != _type) _category = null;
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              style: amountStyle(context, size: 28, color: accent),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Kategori', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in cats)
                  ChoiceChip(
                    avatar: Icon(iconFor(cat.iconName),
                        size: 18, color: hexToColor(cat.colorHex)),
                    label: Text(cat.name),
                    selected: _category?.id == cat.id,
                    onSelected: (_) => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Judul (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(Fmt.date(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
