import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../theme/neo_theme.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/neo_input.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _repo = CashFlowRepository();
  List<Category> _categories = [];
  Map<String, Budget> _budgets = {};
  Map<String, double> _spent = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    setState(() => _loading = true);
    final cats = await _repo.getCategories(type: 'EXPENSE');
    final budgets = await _repo.getBudgets(walletId);
    final now = DateTime.now();

    final budgetMap = <String, Budget>{};
    for (final b in budgets) {
      budgetMap[b.categoryName] = b;
    }

    final spentMap = <String, double>{};
    for (final c in cats) {
      spentMap[c.name] = await _repo.getSpentForCategory(
        walletId: walletId,
        categoryName: c.name,
        month: now.month,
        year: now.year,
      );
    }

    if (!mounted) return;
    setState(() {
      _categories = cats;
      _budgets = budgetMap;
      _spent = spentMap;
      _loading = false;
    });
  }

  Future<void> _editBudget(Category c) async {
    final l10n = AppLocalizations.of(context)!;
    final existing = _budgets[c.name];
    final ctrl = TextEditingController(
        text: existing?.limitAmount.toStringAsFixed(0) ?? '');

    final result = await showNeoDialog<double>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoDialogTitle('${l10n.translate('budget')} — ${c.name}'),
          NeoInput(
            controller: ctrl,
            label: 'Batas Maksimal (IDR)',
            hint: '0',
            prefixIcon: LucideIcons.banknote,
            keyboardType: TextInputType.number,
          ),
          NeoDialogActions(
            children: [
              if (existing != null)
                NeoButton(
                  label: l10n.translate('delete'),
                  variant: NeoButtonVariant.danger,
                  onPressed: () async {
                    await _repo.deleteBudget(existing.id!);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _load();
                    AppEvents.notify();
                  },
                ),
              NeoButton(
                label: l10n.translate('cancel'),
                variant: NeoButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
              NeoButton(
                label: l10n.translate('save'),
                onPressed: () =>
                    Navigator.pop(context, double.tryParse(ctrl.text) ?? 0),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      await _repo.setBudget(Budget(
        id: existing?.id,
        walletId: AppState.activeWalletId!,
        categoryName: c.name,
        limitAmount: result,
      ));
      _load();
      AppEvents.notify();
    }
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
        title: Text(l10n.translate('budget'),
            style: NeoText.display(18, color: ink)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = _categories[i];
                final b = _budgets[c.name];
                final spent = _spent[c.name] ?? 0.0;
                final limit = b?.limitAmount ?? 0.0;
                final isOver = limit > 0 && spent > limit;
                double pct = limit > 0 ? (spent / limit) : 0.0;
                if (pct > 1.0) pct = 1.0;

                return GestureDetector(
                  onTap: () => _editBudget(c),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Neo.paper(context),
                      borderRadius: BorderRadius.circular(NeoRadius.lg),
                      border: isOver
                          ? Border.all(color: NeoColors.red, width: 3)
                          : NeoBorders.reg(ink),
                      boxShadow: NeoShadows.sm(ink),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(c.name,
                                  style: NeoText.display(14, color: ink)),
                            ),
                            Icon(LucideIcons.pencil,
                                size: 16, color: ink.withValues(alpha: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (limit == 0)
                          Text(l10n.translate('no_budget'),
                              style: NeoText.body(12,
                                  color: ink.withValues(alpha: 0.5)))
                        else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatCurrency(spent),
                                style: NeoText.label(12,
                                    color: isOver
                                        ? NeoColors.red
                                        : NeoColors.green),
                              ),
                              Text('dari ${formatCurrency(limit)}',
                                  style: NeoText.label(10,
                                      color: ink.withValues(alpha: 0.5))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Neo.paper(context),
                              borderRadius: BorderRadius.circular(4),
                              border: NeoBorders.thin(ink),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isOver
                                      ? NeoColors.red
                                      : NeoColors.lime,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          if (isOver)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Melebihi anggaran sebesar ${formatCurrency(spent - limit)}!',
                                style: NeoText.body(11,
                                    weight: FontWeight.w700,
                                    color: NeoColors.red),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}