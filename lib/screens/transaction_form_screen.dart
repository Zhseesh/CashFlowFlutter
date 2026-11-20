import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/attachment_service.dart';
import '../theme/neo_theme.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_input.dart';
import '../widgets/neo_dropdown.dart';
import '../widgets/neo_toast.dart';
import '../widgets/neo_fab.dart';
import 'category_management_screen.dart';

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
      _amountCtrl.text = NumberFormat.decimalPattern('en_US').format(e.amount);
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
      NeoToast.show(context, 'Gagal: $e');
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
      NeoToast.show(context, 'Gagal buka: $e');
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

      final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
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
      NeoToast.show(context, 'Gagal simpan: $e');
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final id = widget.editing?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.translate('delete_confirm')),
        content: Text('"${widget.editing!.title}" ${l10n.translate('delete_msg')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NeoColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('delete')),
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
      NeoToast.show(context, 'Gagal hapus: $e');
    }
  }

  // ── TYPE TOGGLE (Neo) ─────────────────────────────────
  Widget _buildTypeToggle() {
    final ink = Neo.ink(context);
    final isIncome = _type == 'INCOME';

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _saving
                ? null
                : () {
                    setState(() {
                      _type = 'INCOME';
                      _category = null;
                    });
                    _loadCategories();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isIncome ? NeoColors.lime : Neo.paper(context),
                borderRadius: BorderRadius.circular(NeoRadius.reg),
                border: NeoBorders.reg(ink),
                boxShadow: isIncome ? NeoShadows.sm(ink) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.arrowDownLeft, size: 16,
                      color: NeoColors.inkLight),
                  const SizedBox(width: 6),
                  Text(l10nIncomeLabel(), style: NeoText.label(11,
                      color: NeoColors.inkLight)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _saving
                ? null
                : () {
                    setState(() {
                      _type = 'EXPENSE';
                      _category = null;
                    });
                    _loadCategories();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: !isIncome ? NeoColors.pink : Neo.paper(context),
                borderRadius: BorderRadius.circular(NeoRadius.reg),
                border: NeoBorders.reg(ink),
                boxShadow: !isIncome ? NeoShadows.sm(ink) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.arrowUpRight, size: 16,
                      color: NeoColors.inkLight),
                  const SizedBox(width: 6),
                  Text(l10nExpenseLabel(), style: NeoText.label(11,
                      color: NeoColors.inkLight)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String l10nIncomeLabel() =>
      AppLocalizations.of(context)!.translate('income').toUpperCase();
  String l10nExpenseLabel() =>
      AppLocalizations.of(context)!.translate('expense').toUpperCase();

  // ── CATEGORY DROPDOWN (Neo) ───────────────────────────
  Widget _buildCategoryField() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end, // Agar tombol sejajar bawah dengan input
      children: [
        Expanded(
          child: NeoDropdown<Category>(
            label: l10n.translate('category'), // Label otomatis di sini
            value: _category,
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: _saving ? null : (c) => setState(() => _category = c),
          ),
        ),
        const SizedBox(width: 10),
        // Tombol Pengaturan Kategori
        Padding(
          padding: const EdgeInsets.only(bottom: 2), // Sedikit adjust
          child: NeoFab(
            icon: LucideIcons.slidersHorizontal,
            color: NeoColors.yellow,
            onTap: _saving
                ? () {}
                : () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
                    _loadCategories();
                  },
          ),          
        ),
      ],
    );
  }

  // ── DATE FIELD (Neo) ──────────────────────────────────
  Widget _buildDateField() {
    final ink = Neo.ink(context);
    return GestureDetector(
      onTap: _saving ? null : _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Neo.paper(context),
          borderRadius: BorderRadius.circular(NeoRadius.reg),
          border: NeoBorders.reg(ink),
          boxShadow: NeoShadows.sm(ink),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.calendarDays, size: 18, color: ink),
                const SizedBox(width: 10),
                Text(formatDate(_date),
                    style: NeoText.body(14, weight: FontWeight.w600, color: ink)),
              ],
            ),
            Icon(LucideIcons.pencil, size: 16,
                color: ink.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── ATTACHMENT SECTION (Neo) ──────────────────────────
  Widget _buildAttachmentSection() {
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(l10n.translate('attachment').toUpperCase(),
              style: NeoText.label(10, color: ink)),
        ),

        ..._existingAttachments.map((path) => _buildAttachmentRow(
              ink: ink,
              label: l10n.translate('saved_attachment'),
              subtitle: null,
              iconBg: NeoColors.lime,
              icon: LucideIcons.paperclip,
              onView: () => _viewFile(path),
              onRemove: () => _removeExisting(path),
            )),

        ..._newTempAttachments.map((path) => _buildAttachmentRow(
              ink: ink,
              label: p.basename(path),
              subtitle: l10n.translate('unsaved_attachment'),
              iconBg: NeoColors.orange,
              icon: LucideIcons.cloudUpload,
              onView: () => _viewFile(path, isTemp: true),
              onRemove: () => _removeNewTemp(path),
            )),

        const SizedBox(height: 6),
        NeoButton(
          label: l10n.translate('add_attachment'),
          icon: LucideIcons.plus,
          variant: NeoButtonVariant.ghost,
          expanded: true,
          onPressed: _saving ? null : _pickAttachment,
        ),
      ],
    );
  }

  Widget _buildAttachmentRow({
    required Color ink,
    required String label,
    required String? subtitle,
    required Color iconBg,
    required IconData icon,
    required VoidCallback onView,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Neo.paper(context),
          borderRadius: BorderRadius.circular(NeoRadius.reg),
          border: NeoBorders.reg(ink),
          boxShadow: NeoShadows.sm(ink),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                border: NeoBorders.thin(ink),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: NeoColors.inkLight),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: NeoText.body(12, weight: FontWeight.w700, color: ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: NeoText.label(9,
                            color: ink.withValues(alpha: 0.6))),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.eye, size: 18,
                  color: ink.withValues(alpha: 0.7)),
              onPressed: onView,
            ),
            IconButton(
              icon: Icon(LucideIcons.x, size: 18,
                  color: ink.withValues(alpha: 0.7)),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing
              ? l10n.translate('edit_transaction')
              : l10n.translate('new_transaction'),
          style: NeoText.display(18, color: ink),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: l10n.translate('delete'),
              icon: const Icon(LucideIcons.trash2, color: NeoColors.red),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 24),

            NeoInput(
              controller: _titleCtrl,
              label: l10n.translate('title'),
              hint: l10n.translate('title_hint'),
              prefixIcon: LucideIcons.type,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            NeoInput(
              controller: _amountCtrl,
              label: l10n.translate('amount'),
              hint: '0',
              prefixIcon: LucideIcons.banknote,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                CurrencyInputFormatter(),
              ],
              textStyle: NeoText.display(24, color: ink),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final n = double.tryParse(v.replaceAll(',', ''));
                if (n == null || n <= 0) return 'Tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildCategoryField(),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(l10n.translate('date').toUpperCase(),
                  style: NeoText.label(10, color: ink)),
            ),
            _buildDateField(),
            const SizedBox(height: 16),

            NeoInput(
              controller: _noteCtrl,
              label: l10n.translate('note'),
              hint: l10n.translate('note_hint'),
              prefixIcon: LucideIcons.alignLeft,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            _buildAttachmentSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Neo.paper(context),
          border: Border(top: BorderSide(color: ink, width: 4)),
        ),
        child: SafeArea(
          child: NeoButton(
            label: _isEditing
                ? l10n.translate('update')
                : l10n.translate('save'),
            expanded: true,
            loading: _saving,
            icon: _isEditing ? LucideIcons.checkCheck : LucideIcons.check,
            variant: _type == 'INCOME'
                ? NeoButtonVariant.income
                : NeoButtonVariant.expense,
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
    );
  }
}