import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
import '../models/transaction.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';
import 'wallet_management_screen.dart';

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
    AppState.activeWallet.addListener(_onWalletChanged);
    _load();
  }

  @override
  void dispose() {
    AppEvents.dataChanged.removeListener(_load);
    AppState.activeWallet.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    _load();
  }

  Future<void> _load() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    setState(() => _loading = true);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final balance = await _repo.getCurrentBalance(walletId);
    final inc = await _repo.totalByType('INCOME', walletId: walletId, from: start, to: end);
    final exp = await _repo.totalByType('EXPENSE', walletId: walletId, from: start, to: end);
    final recent = await _repo.getTransactions(walletId: walletId, limit: 5);
    
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _incomeMonth = inc;
      _expenseMonth = exp;
      _recent = recent;
      _loading = false;
    });
  }

  void _openAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );
  }

  void _openEditScreen(TransactionRecord tx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormScreen(editing: tx)),
    );
  }

  void _openWalletManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _openWalletManagement,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder(
                  valueListenable: AppState.activeWallet,
                  builder: (context, wallet, _) {
                    return Text(
                      wallet?.name ?? 'Pilih Tabungan',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScreen,
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                    ..._recent.map((t) => TransactionTile(
                      transaction: t,
                      onTap: _openEditScreen,
                    )),
                ],
              ),
            ),
    );
  }
}