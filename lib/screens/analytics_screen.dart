import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
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

  static const _monthNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];

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
    final breakdown = await _repo.categoryBreakdown('EXPENSE', walletId: walletId, from: start, to: end);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalBreak = _breakdown.fold<double>(0, (p, e) => p + e.total);

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  const Text('Analisis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // ── GRAFIK CARD ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grafik Tahunan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.chevron_left, size: 16),
                                    onPressed: () { setState(() => _year--); _load(); },
                                  ),
                                  Text('$_year', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.chevron_right, size: 16),
                                    onPressed: () { setState(() => _year++); _load(); },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _maxY(),
                              barTouchData: BarTouchData(enabled: false),
                              gridData: FlGridData(
                                show: true, 
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(_monthNames[v.toInt() - 1], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
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
                                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFA7F3D0), // Warna Light/Dark
                                      width: 6,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    BarChartRodData(
                                      toY: d.expense,
                                      color: const Color(0xFF10B981), // Warna Utama
                                      width: 6,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── RINCIAN PENGELUARAN ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rincian Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _month,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                items: List.generate(12, (i) => DropdownMenuItem(
                                  value: i + 1, 
                                  child: Text(_monthNames[i]),
                                )),
                                onChanged: (v) { setState(() => _month = v!); _load(); },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_breakdown.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('Belum ada pengeluaran bulan ini.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ),
                          )
                        else
                          ..._breakdown.map((b) {
                            final pct = totalBreak == 0 ? 0.0 : b.total / totalBreak;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(b.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      Text('${(pct * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 6,
                                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(formatCurrency(b.total), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}