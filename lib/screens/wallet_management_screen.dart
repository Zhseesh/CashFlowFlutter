import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';

class WalletManagementScreen extends StatefulWidget {
  const WalletManagementScreen({super.key});

  @override
  State<WalletManagementScreen> createState() => _WalletManagementScreenState();
}

class _WalletManagementScreenState extends State<WalletManagementScreen> {
  final _repo = CashFlowRepository();
  List<Wallet> _wallets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getWallets();
    if (!mounted) return;
    setState(() {
      _wallets = list;
      _loading = false;
    });
  }

  Future<void> _addWallet() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(); 

    final result = await showDialog<({String name, double balance})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.translate('add_wallet_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.translate('wallet_name'),
                  hintText: l10n.translate('wallet_name_hint'),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  CurrencyInputFormatter()
                ],
                decoration: InputDecoration(
                  labelText: l10n.translate('initial_balance'),
                  prefixText: 'IDR ',
                  hintText: '0.00',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(l10n.translate('cancel'))
            ),
            FilledButton(
              onPressed: () {
                final balanceStr = balanceCtrl.text.replaceAll(',', '');
                final balance = double.tryParse(balanceStr) ?? 0.0;
                Navigator.pop(context, (name: nameCtrl.text.trim(), balance: balance));
              },
              child: Text(l10n.translate('save')),
            ),
          ],
        );
      },
    );

    if (result == null || result.name.isEmpty) return;

    final newWalletId = await _repo.insertWallet(Wallet(
      name: result.name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    if (result.balance > 0) {
      final categories = await _repo.getCategories(type: 'INCOME');
      final defaultCategory = categories.firstWhere(
        (c) => c.name == 'Lainnya',
        orElse: () => categories.first,
      );

      final tx = TransactionRecord(
        walletId: newWalletId,
        title: 'Saldo Awal',
        amount: result.balance,
        type: 'INCOME',
        categoryId: defaultCategory.id,
        categoryName: defaultCategory.name,
        dateMillis: DateTime.now().millisecondsSinceEpoch,
        note: 'Saldo awal saat pembuatan tabungan',
      );
      await _repo.insertTransaction(tx);
    }

    _load();
    AppEvents.notify();
  }

  Future<void> _editWallet(Wallet w) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: w.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.translate('edit_category')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: l10n.translate('wallet_name')),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.translate('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(l10n.translate('save')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == w.name) return;
    
    await _repo.updateWalletName(w.id!, name);
    if (AppState.activeWallet.value?.id == w.id) {
      AppState.activeWallet.value = Wallet(id: w.id, name: name, createdAt: w.createdAt);
    }
    _load();
  }

  Future<void> _deleteWallet(Wallet w) async {
    final l10n = AppLocalizations.of(context)!;
    if (_wallets.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('cannot_delete_last_wallet'))),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.translate('delete_wallet_confirm')),
        content: Text('${l10n.translate('delete_wallet_msg')} "${w.name}" ${l10n.translate('delete_wallet_msg2')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.translate('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _repo.deleteWallet(w.id!);
    if (AppState.activeWallet.value?.id == w.id) {
      final remaining = await _repo.getWallets();
      AppState.activeWallet.value = remaining.first;
    }
    _load();
    AppEvents.notify();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('manage_wallet'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Material(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _wallets.length; i++) ...[
                        _buildWalletTile(_wallets[i], isDark),
                        if (i < _wallets.length - 1)
                          Divider(
                            height: 1,
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                          ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWallet,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: const Color(0xFF10B981),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.translate('wallet'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWalletTile(Wallet w, bool isDark) {
    final isActive = AppState.activeWallet.value?.id == w.id;
    final l10n = AppLocalizations.of(context)!;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        AppState.activeWallet.value = w;
        Navigator.pop(context);
      },
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50),
          shape: BoxShape.circle,
          border: isActive ? null : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
        ),
        child: Icon(
          isActive ? Icons.check : Icons.account_balance_wallet_outlined,
          color: isActive ? const Color(0xFF10B981) : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        w.name,
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 14, 
          color: isActive ? const Color(0xFF10B981) : null
        ),
      ),
      subtitle: Text(
        '${l10n.translate('created_at')} ${formatDate(DateTime.fromMillisecondsSinceEpoch(w.createdAt))}',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: Colors.grey,
            onPressed: () => _editWallet(w),
          ),
          if (_wallets.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.grey,
              onPressed: () => _deleteWallet(w),
            ),
        ],
      ),
    );
  }
}