import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/controller_scope.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'widgets/app_card.dart';
import 'widgets/charts.dart';
import 'widgets/month_picker.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final theme = Theme.of(context);
    final m = c.analyticsMonth;
    final net = c.analyticsIncome - c.analyticsExpense;
    final sum = c.breakdown.fold<double>(0, (s, e) => s + e.total);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('Analisis',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () =>
                      c.setAnalyticsMonth(DateTime(m.year, m.month - 1)),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showMonthYearPicker(context, m);
                      if (picked != null) c.setAnalyticsMonth(picked);
                    },
                    child: Text(Fmt.monthYear(m),
                        style: theme.textTheme.titleMedium),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      c.setAnalyticsMonth(DateTime(m.year, m.month + 1)),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _Mini(
                      label: 'Pemasukan',
                      value: c.analyticsIncome,
                      color: AppColors.income)),
              const SizedBox(width: 8),
              Expanded(
                  child: _Mini(
                      label: 'Pengeluaran',
                      value: c.analyticsExpense,
                      color: AppColors.expense)),
              const SizedBox(width: 8),
              Expanded(
                  child: _Mini(
                      label: 'Selisih',
                      value: net,
                      color: net >= 0 ? AppColors.income : AppColors.expense)),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pemasukan vs Pengeluaran',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('6 bulan hingga ${Fmt.monthYear(m)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 10),
                const ChartLegend(),
                const SizedBox(height: 12),
                ComparisonBarChart(data: c.analyticsSeries, height: 210),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rincian per Kategori',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TxType>(
                    segments: const [
                      ButtonSegment(
                          value: TxType.expense, label: Text('Pengeluaran')),
                      ButtonSegment(
                          value: TxType.income, label: Text('Pemasukan')),
                    ],
                    selected: {c.breakdownType},
                    onSelectionChanged: (s) => c.setBreakdownType(s.first),
                  ),
                ),
                const SizedBox(height: 8),
                if (c.breakdown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Belum ada data bulan ini.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  )
                else
                  for (final item in c.breakdown)
                    CategoryBar(
                      item: item,
                      fraction: sum == 0 ? 0 : item.total / sum,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Fmt.rupiah(value),
                style: amountStyle(context, size: 14, color: color)),
          ),
        ],
      ),
    );
  }
}
