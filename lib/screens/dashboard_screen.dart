import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../theme/neo_theme.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/balance_card.dart';
import '../widgets/neo_chip.dart';
import '../widgets/neo_input.dart';
import '../widgets/neo_skeleton.dart';
import '../widgets/neo_fab.dart';
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
  double _incomeTotal = 0;
  double _expenseTotal = 0;
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

    final balance = await _repo.getCurrentBalance(walletId);
    final inc = await _repo.totalByType('INCOME', walletId: walletId);
    final exp = await _repo.totalByType('EXPENSE', walletId: walletId);

    final txs = await _repo.getTransactions(
      walletId: walletId,
      from: _dateRange?.start,
      to: _dateRange?.end != null
          ? DateTime(_dateRange!.end.year, _dateRange!.end.month,
              _dateRange!.end.day, 23, 59, 59)
          : null,
      searchQuery: _searchCtrl.text,
      limit: _isFiltering ? 10000 : 5,
    );

    if (!mounted) return;
    setState(() {
      _balance = balance;
      _incomeTotal = inc;
      _expenseTotal = exp;
      _transactions = txs;
      _loading = false;
    });
  }

  void _openEditScreen(TransactionRecord tx) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => TransactionFormScreen(editing: tx)));
  }

  void _openWalletManagement() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const WalletManagementScreen()));
  }

  void _openSettings() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: NeoColors.yellow,
          backgroundColor: ink,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ── HEADER: wallet switcher + settings button ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _openWalletManagement,
                    child: Row(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: AppState.activeWallet,
                          builder: (context, wallet, _) {
                            return Text(
                              wallet?.name ?? l10n.translate('main_wallet'),
                              style: NeoText.display(22, color: ink),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronDown, size: 22, color: ink),
                      ],
                    ),
                  ),
                  NeoFab(
                    icon: LucideIcons.settings,
                    color: NeoColors.cyan,
                    size: 44,
                    radius: 12,
                    onTap: _openSettings,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── BALANCE CARD ──
              BalanceCard(
                balance: _balance,
                income: _incomeTotal,
                expense: _expenseTotal,
              ),
              const SizedBox(height: 22),

              // ── SEARCH BAR ──
              NeoInput(
                controller: _searchCtrl,
                hint: l10n.translate('search_hint'),
                prefixIcon: LucideIcons.search,
                isSearch: true,
                onChanged: (_) => _load(),
                suffix: IconButton(
                  icon: Icon(LucideIcons.calendar, size: 20, color: ink),
                  onPressed: _pickDateRange,
                ),
              ),

              // ── FILTER CHIP ──
              if (_isFiltering)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_dateRange != null)
                        NeoChip(
                          emoji: '📅',
                          label:
                              '${formatDate(_dateRange!.start)} - ${formatDate(_dateRange!.end)}',
                          onDeleted: () {
                            setState(() => _dateRange = null);
                            _load();
                          },
                        ),
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _dateRange = null);
                          _load();
                        },
                        child: Text(
                          l10n.translate('reset').toUpperCase(),
                          style: NeoText.label(11, color: ink),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ── SECTION HEADER ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.translate('recent_transactions').toUpperCase(),
                    style: NeoText.display(16, color: ink),
                  ),
                  if (_isFiltering)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NeoColors.purple,
                        borderRadius: BorderRadius.circular(6),
                        border: NeoBorders.thin(ink),
                      ),
                      child: Text(
                        '${_transactions.length}',
                        style: NeoText.label(10, color: NeoColors.inkLight),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // ── TRANSACTIONS ──
              if (_loading)
                const NeoSkeletonList(count: 5)
              else if (_transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Neo.paper(context),
                    borderRadius: BorderRadius.circular(NeoRadius.lg),
                    border: NeoBorders.reg(ink),
                    boxShadow: NeoShadows.sm(ink),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: NeoColors.cyan,
                          borderRadius: BorderRadius.circular(16),
                          border: NeoBorders.reg(ink),
                        ),
                        child: Icon(
                          _isFiltering ? LucideIcons.searchX : LucideIcons.receipt,
                          size: 30,
                          color: NeoColors.inkLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate('no_transactions'),
                        style: NeoText.body(14, weight: FontWeight.w700, color: ink),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate('no_transactions_sub'),
                        style: NeoText.body(12,
                            color: ink.withValues(alpha: 0.6)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._transactions.map((t) => TransactionTile(
                      transaction: t,
                      onTap: _openEditScreen,
                    )),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}