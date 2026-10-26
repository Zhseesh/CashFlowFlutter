import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
import '../models/transaction.dart';
import '../utils/app_events.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = CashFlowRepository();
  double _balance = 0;
  double _incomeMonth = 0;
  double _expenseMonth = 0;
  List<TransactionRecord> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppEvents.dataChanged.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppEvents.dataChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final balance = await _repo.getCurrentBalance();
    final inc = await _repo.totalByType('INCOME', from: start, to: end);
    final exp = await _repo.totalByType('EXPENSE', from: start, to: end);
    final recent = await _repo.getTransactions(limit: 5);
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _incomeMonth = inc;
      _expenseMonth = exp;
      _recent = recent;
      _loading = false;
    });
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Transaksi'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  BalanceCard(balance: _balance, income: _incomeMonth, expense: _expenseMonth),
                  const SizedBox(height: 24),
                  const Text('Transaksi Terbaru',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48),
                          SizedBox(height: 8),
                          Text('Belum ada transaksi', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ..._recent.map((t) => TransactionTile(transaction: t, onChanged: _load)),
                ],
              ),
            ),
    );
  }
}