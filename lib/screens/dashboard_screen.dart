import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';
import 'wallet_management_screen.dart';
import 'settings_screen.dart'; 

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
  List<TransactionRecord> _transactions = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  DateTimeRange? _dateRange;
  bool get _isFiltering => _searchCtrl.text.isNotEmpty || _dateRange != null;

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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onWalletChanged() {
    _searchCtrl.clear();
    setState(() => _dateRange = null);
    _load();
  }

  Future<void> _load() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    setState(() => _loading = true);
    
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final endMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final balance = await _repo.getCurrentBalance(walletId);
    final inc = await _repo.totalByType('INCOME', walletId: walletId, from: startMonth, to: endMonth);
    final exp = await _repo.totalByType('EXPENSE', walletId: walletId, from: startMonth, to: endMonth);

    final txs = await _repo.getTransactions(
      walletId: walletId,
      from: _dateRange?.start,
      to: _dateRange?.end != null 
          ? DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59)
          : null,
      searchQuery: _searchCtrl.text,
      limit: _isFiltering ? 10000 : 5, 
    );
    
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _incomeMonth = inc;
      _expenseMonth = exp;
      _transactions = txs;
      _loading = false;
    });
  }

  void _openEditScreen(TransactionRecord tx) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(editing: tx)));
  }

  void _openWalletManagement() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletManagementScreen()));
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _openWalletManagement,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: AppState.activeWallet,
                          builder: (context, wallet, _) {
                            return Text(
                              wallet?.name ?? l10n.translate('main_wallet'), // <-- DINAMIS
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 24, color: Colors.grey),
                      ],
                    ),
                  ),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      onPressed: _openSettings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              BalanceCard(balance: _balance, income: _incomeMonth, expense: _expenseMonth),
              const SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _load(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_hint'), // <-- DINAMIS
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month, size: 20),
                      onPressed: _pickDateRange,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              if (_isFiltering)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (_dateRange != null)
                        Chip(
                          label: Text('${formatDate(_dateRange!.start)} - ${formatDate(_dateRange!.end)}', style: const TextStyle(fontSize: 11)),
                          onDeleted: () { setState(() => _dateRange = null); _load(); },
                        ),
                      TextButton(
                        onPressed: () { _searchCtrl.clear(); setState(() => _dateRange = null); _load(); },
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('recent_transactions'), // <-- DINAMIS
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_isFiltering)
                    Text('${_transactions.length} ditemukan', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_isFiltering ? Icons.search_off : Icons.receipt_long_outlined, size: 32, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate('no_transactions'), // <-- DINAMIS
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate('no_transactions_sub'), // <-- DINAMIS
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ..._transactions.map((t) => TransactionTile(
                  transaction: t,
                  onTap: _openEditScreen,
                )),
                
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }
}