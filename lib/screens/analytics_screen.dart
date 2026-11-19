import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/neo_theme.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _repo = CashFlowRepository();
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  Map<int, ({double income, double expense})> _monthly = {};
  List<({String category, double total})> _breakdown = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppState.activeWallet.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppState.activeWallet.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    setState(() => _loading = true);
    final monthly = await _repo.monthlyTotals(_year, walletId: walletId);
    final start = DateTime(_year, _month, 1);
    final end = DateTime(_year, _month + 1, 0, 23, 59, 59);
    final breakdown = await _repo.categoryBreakdown('EXPENSE',
        walletId: walletId, from: start, to: end);
    if (!mounted) return;
    setState(() {
      _monthly = monthly;
      _breakdown = breakdown;
      _loading = false;
    });
  }

  double _maxY() {
    double m = 1000;
    for (final d in _monthly.values) {
      if (d.income > m) m = d.income;
      if (d.expense > m) m = d.expense;
    }
    return m * 1.15;
  }

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;
    final totalBreak = _breakdown.fold<double>(0, (p, e) => p + e.total);

    final monthNames = List.generate(
      12,
      (i) => DateFormat('MMM', Localizations.localeOf(context).languageCode)
          .format(DateTime(2024, i + 1, 1)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Text(l10n.translate('analytics').toUpperCase(),
                      style: NeoText.display(22, color: ink)),
                  const SizedBox(height: 20),

                  // ── YEARLY CHART CARD (Cyan) ──────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: NeoColors.cyan,
                      borderRadius: BorderRadius.circular(NeoRadius.lg),
                      border: NeoBorders.thick(ink),
                      boxShadow: NeoShadows.md(ink),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.translate('yearly_chart').toUpperCase(),
                              style: NeoText.label(11,
                                  color: NeoColors.inkLight),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NeoColors.paperLight,
                                border: NeoBorders.thin(NeoColors.inkLight),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 18,
                                    icon: const Icon(LucideIcons.chevronLeft,
                                        size: 18, color: NeoColors.inkLight),
                                    onPressed: () {
                                      setState(() => _year--);
                                      _load();
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text('$_year',
                                        style: NeoText.label(12,
                                            color: NeoColors.inkLight)),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(LucideIcons.chevronRight,
                                        size: 18, color: NeoColors.inkLight),
                                    onPressed: () {
                                      setState(() => _year++);
                                      _load();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _maxY(),
                              barTouchData: BarTouchData(enabled: false),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        monthNames[v.toInt() - 1],
                                        style: NeoText.label(9,
                                            color: NeoColors.inkLight),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              barGroups: List.generate(12, (i) {
                                final m = i + 1;
                                final d = _monthly[m] ??
                                    (income: 0.0, expense: 0.0);
                                return BarChartGroupData(
                                  x: m,
                                  barsSpace: 2,
                                  barRods: [
                                    BarChartRodData(
                                      toY: d.income,
                                      color: NeoColors.lime,
                                      width: 6,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    BarChartRodData(
                                      toY: d.expense,
                                      color: NeoColors.pink,
                                      width: 6,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legend(NeoColors.lime,
                                l10n.translate('income'), ink),
                            const SizedBox(width: 16),
                            _legend(NeoColors.pink,
                                l10n.translate('expense'), ink),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── EXPENSE BREAKDOWN CARD ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Neo.paper(context),
                      borderRadius: BorderRadius.circular(NeoRadius.lg),
                      border: NeoBorders.reg(ink),
                      boxShadow: NeoShadows.sm(ink),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.translate('expense_breakdown').toUpperCase(),
                                style: NeoText.display(14, color: ink),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: NeoColors.purple,
                                borderRadius: BorderRadius.circular(8),
                                border: NeoBorders.thin(ink),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _month,
                                  isDense: true,
                                  dropdownColor: NeoColors.purple,
                                  icon: Icon(LucideIcons.chevronDown,
                                      size: 16, color: ink),
                                  style: NeoText.label(11,
                                      color: NeoColors.inkLight),
                                  items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text(monthNames[i]),
                                    ),
                                  ),
                                  onChanged: (v) {
                                    setState(() => _month = v!);
                                    _load();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_breakdown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                l10n.translate('no_expense_month'),
                                style: NeoText.body(12,
                                    color: ink.withValues(alpha: 0.5)),
                              ),
                            ),
                          )
                        else
                          ..._breakdown.map((b) {
                            final pct =
                                totalBreak == 0 ? 0.0 : b.total / totalBreak;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(b.category,
                                            style: NeoText.body(13,
                                                weight: FontWeight.w600,
                                                color: ink)),
                                      ),
                                      Text(
                                        '${(pct * 100).toStringAsFixed(1)}%',
                                        style: NeoText.label(11,
                                            color: ink.withValues(alpha: 0.6)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 10,
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
                                          color: NeoColors.pink,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(formatCurrency(b.total),
                                      style: NeoText.label(10,
                                          color: ink.withValues(alpha: 0.5))),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
      ),
    );
  }

  Widget _legend(Color color, String label, Color ink) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: NeoBorders.thin(ink),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label.toUpperCase(),
            style: NeoText.label(9, color: NeoColors.inkLight)),
      ],
    );
  }
}