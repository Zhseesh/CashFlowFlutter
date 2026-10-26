import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
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

  static const _monthNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final monthly = await _repo.monthlyTotals(_year);
    final start = DateTime(_year, _month, 1);
    final end = DateTime(_year, _month + 1, 0, 23, 59, 59);
    final breakdown = await _repo.categoryBreakdown('EXPENSE', from: start, to: end);
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
    final totalBreak = _breakdown.fold<double>(0, (p, e) => p + e.total);
    return Scaffold(
      appBar: AppBar(title: const Text('Analisis', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grafik Tahunan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(children: [
                              IconButton(
                                onPressed: () {
                                  setState(() => _year--);
                                  _load();
                                },
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text('$_year', style: const TextStyle(fontWeight: FontWeight.w600)),
                              IconButton(
                                onPressed: () {
                                  setState(() => _year++);
                                  _load();
                                },
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _maxY(),
                              barTouchData: BarTouchData(enabled: false),
                              gridData: FlGridData(show: true, drawVerticalLine: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(_monthNames[v.toInt() - 1],
                                          style: const TextStyle(fontSize: 9)),
                                    ),
                                  ),
                                ),
                              ),
                              barGroups: List.generate(12, (i) {
                                final m = i + 1;
                                final d = _monthly[m] ?? (income: 0.0, expense: 0.0);
                                return BarChartGroupData(
                                  x: m,
                                  barsSpace: 2,
                                  barRods: [
                                    BarChartRodData(
                                        toY: d.income,
                                        color: const Color(0xFF10B981),
                                        width: 5,
                                        borderRadius: BorderRadius.circular(2)),
                                    BarChartRodData(
                                        toY: d.expense,
                                        color: const Color(0xFFE11D48),
                                        width: 5,
                                        borderRadius: BorderRadius.circular(2)),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pengeluaran ${_monthNames[_month - 1]} $_year',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            DropdownButton<int>(
                              value: _month,
                              underline: const SizedBox(),
                              items: List.generate(
                                  12,
                                  (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text(_monthNames[i],
                                          style: const TextStyle(fontSize: 13)))),
                              onChanged: (v) {
                                setState(() => _month = v!);
                                _load();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_breakdown.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Belum ada pengeluaran bulan ini.',
                                style: TextStyle(color: Colors.grey)),
                          )
                        else
                          ..._breakdown.map((b) {
                            final pct = totalBreak == 0 ? 0.0 : b.total / totalBreak;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(b.category,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w500)),
                                      Text(
                                        '${(pct * 100).toStringAsFixed(1)}% • ${formatCurrency(b.total)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.withOpacity(0.15),
                                    color: const Color(0xFFE11D48),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}