import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';

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

    final Map<String, Budget> budgetMap = {};
    for (final b in budgets) { budgetMap[b.categoryName] = b; }

    final Map<String, double> spentMap = {};
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
    final ctrl = TextEditingController(text: existing?.limitAmount.toStringAsFixed(0) ?? '');
    
    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${l10n.translate('budget')}: ${c.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Batas Maksimal (Rp)', prefixText: 'Rp '),
          autofocus: true,
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await _repo.deleteBudget(existing.id!);
                if (!mounted) return;
                Navigator.pop(context);
                _load();
                AppEvents.notify();
              }, 
              child: Text(l10n.translate('delete'), style: const TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text) ?? 0),
            child: Text(l10n.translate('save')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('budget'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = _categories[i];
                final b = _budgets[c.name];
                final spent = _spent[c.name] ?? 0.0;
                final limit = b?.limitAmount ?? 0.0;
                final isOver = limit > 0 && spent > limit;
                
                double pct = limit > 0 ? (spent / limit) : 0.0;
                if (pct > 1.0) pct = 1.0;

                return Material(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isOver 
                          ? Colors.red.withValues(alpha: 0.5) 
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200)
                    ),
                  ),
                  clipBehavior: Clip.antiAlias, // <-- KUNCI AGAR RIPPLE RAPI
                  child: InkWell(
                    onTap: () => _editBudget(c),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (limit == 0)
                            Text(l10n.translate('no_budget'), style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                          else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatCurrency(spent), style: TextStyle(fontWeight: FontWeight.bold, color: isOver ? Colors.red : const Color(0xFF10B981), fontSize: 13)),
                                Text('dari ${formatCurrency(limit)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                                color: isOver ? Colors.red : const Color(0xFF10B981),
                              ),
                            ),
                            if (isOver)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('Melebihi anggaran sebesar ${formatCurrency(spent - limit)}!', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}