import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
import '../models/transaction.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';
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
  
  // State Data
  double _balance = 0;
  double _incomeMonth = 0;
  double _expenseMonth = 0;
  List<TransactionRecord> _transactions = [];
  bool _loading = true;

  // State Filter & Search
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
    // Reset filter saat ganti tabungan
    _searchCtrl.clear();
    setState(() => _dateRange = null);
    _load();
  }

  Future<void> _load() async {
    final walletId = AppState.activeWalletId;
    if (walletId == null) return;

    setState(() => _loading = true);
    
    // Data Ringkasan Bulan Ini
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final endMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final balance = await _repo.getCurrentBalance(walletId);
    final inc = await _repo.totalByType('INCOME', walletId: walletId, from: startMonth, to: endMonth);
    final exp = await _repo.totalByType('EXPENSE', walletId: walletId, from: startMonth, to: endMonth);

    // Data Transaksi (dengan filter)
    final txs = await _repo.getTransactions(
      walletId: walletId,
      from: _dateRange?.start,
      to: _dateRange?.end != null 
          ? DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59)
          : null,
      searchQuery: _searchCtrl.text,
      limit: _isFiltering ? 10000 : 5, // Tampilkan semua jika filter aktif, jika tidak 5 terbaru
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

  void _openAddScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );
  }

  void _openEditScreen(TransactionRecord tx) async {
    await Navigator.push(
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _load();
    }
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() => _dateRange = null);
    _load();
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // 1. KARTU SALDO
            BalanceCard(balance: _balance, income: _incomeMonth, expense: _expenseMonth),
            
            const SizedBox(height: 24),
            
            // 2. SEARCH BAR & FILTER
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _load();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (_) => _load(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Filter Tanggal',
                ),
              ],
            ),
            
            // Tampilkan info filter jika aktif
            if (_isFiltering)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_dateRange != null)
                      Chip(
                        label: Text(
                          '${formatDate(_dateRange!.start)} - ${formatDate(_dateRange!.end)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onDeleted: () {
                          setState(() => _dateRange = null);
                          _load();
                        },
                      ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset Filter', style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // 3. LIST TRANSAKSI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isFiltering ? 'Hasil Pencarian' : 'Transaksi Terbaru',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_isFiltering)
                  Text(
                    '${_transactions.length} ditemukan',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    Icon(_isFiltering ? Icons.search_off : Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      _isFiltering ? 'Transaksi tidak ditemukan' : 'Belum ada transaksi',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._transactions.map((t) => TransactionTile(
                transaction: t,
                onTap: _openEditScreen,
              )),
          ],
        ),
      ),
    );
  }
}