import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/cashflow_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../theme/neo_theme.dart';
import '../utils/app_events.dart';
import '../utils/app_state.dart';
import '../utils/formatters.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/neo_fab.dart';
import '../widgets/neo_input.dart';
import '../widgets/neo_toast.dart';
import '../widgets/neo_skeleton.dart';

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

    final result = await showNeoDialog<({String name, double balance})>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoDialogTitle(l10n.translate('add_wallet_title')),
          NeoInput(
            controller: nameCtrl,
            label: l10n.translate('wallet_name'),
            hint: l10n.translate('wallet_name_hint'),
          ),
          const SizedBox(height: 12),
          NeoInput(
            controller: balanceCtrl,
            label: l10n.translate('initial_balance'),
            hint: '0.00',
            prefixIcon: LucideIcons.banknote,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              CurrencyInputFormatter(),
            ],
          ),
          NeoDialogActions(
            children: [
              NeoButton(
                label: l10n.translate('cancel'),
                variant: NeoButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
              NeoButton(
                label: l10n.translate('save'),
                onPressed: () {
                  final balanceStr = balanceCtrl.text.replaceAll(',', '');
                  final balance = double.tryParse(balanceStr) ?? 0.0;
                  Navigator.pop(context,
                      (name: nameCtrl.text.trim(), balance: balance));
                },
              ),
            ],
          ),
        ],
      ),
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
    final name = await showNeoDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoDialogTitle(l10n.translate('edit_category')),
          NeoInput(
            controller: ctrl,
            label: l10n.translate('wallet_name'),
          ),
          NeoDialogActions(
            children: [
              NeoButton(
                label: l10n.translate('cancel'),
                variant: NeoButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
              NeoButton(
                label: l10n.translate('save'),
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == w.name) return;

    await _repo.updateWalletName(w.id!, name);
    if (AppState.activeWallet.value?.id == w.id) {
      AppState.activeWallet.value =
          Wallet(id: w.id, name: name, createdAt: w.createdAt);
    }
    _load();
  }

  Future<void> _deleteWallet(Wallet w) async {
    final l10n = AppLocalizations.of(context)!;
    if (_wallets.length == 1) {
      NeoToast.show(context, (l10n.translate('cannot_delete_last_wallet')));
      return;
    }

    final ok = await showNeoDialog<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoDialogTitle(l10n.translate('delete_wallet_confirm')),
          Text(
            '${l10n.translate('delete_wallet_msg')} "${w.name}" ${l10n.translate('delete_wallet_msg2')}',
            style: NeoText.body(13, color: Neo.ink(context)),
          ),
          NeoDialogActions(
            children: [
              NeoButton(
                label: l10n.translate('cancel'),
                variant: NeoButtonVariant.secondary,
                onPressed: () => Navigator.pop(context, false),
              ),
              NeoButton(
                label: l10n.translate('delete'),
                variant: NeoButtonVariant.danger,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
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
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('manage_wallet'),
            style: NeoText.display(18, color: ink)),
      ),
      body: _loading
          ? Center(child: const NeoSkeletonList(count: 15))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Neo.paper(context),
                    borderRadius: BorderRadius.circular(NeoRadius.lg),
                    border: NeoBorders.reg(ink),
                    boxShadow: NeoShadows.sm(ink),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _wallets.length; i++) ...[
                        _buildWalletTile(_wallets[i], ink, l10n),
                        if (i < _wallets.length - 1)
                          Divider(height: 2, color: ink),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
      floatingActionButton: NeoFab(
        icon: LucideIcons.plus,
        label: l10n.translate('wallet'),
        expanded: true,
        color: NeoColors.lime,
        onTap: _addWallet,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildWalletTile(Wallet w, Color ink, AppLocalizations l10n) {
    final isActive = AppState.activeWallet.value?.id == w.id;

    return GestureDetector(
      onTap: () {
        AppState.activeWallet.value = w;
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                AppState.activeWallet.value = w;
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? NeoColors.lime : NeoColors.cyan,
                  border: NeoBorders.thin(ink),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? LucideIcons.check : LucideIcons.wallet,
                  color: NeoColors.inkLight,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.name,
                      style: NeoText.body(14,
                          weight: FontWeight.w700, color: ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.translate('created_at')} ${formatDate(DateTime.fromMillisecondsSinceEpoch(w.createdAt))}',
                    style: NeoText.label(9,
                        color: ink.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.pencil, size: 18,
                  color: ink.withValues(alpha: 0.7)),
              onPressed: () => _editWallet(w),
            ),
            if (_wallets.length > 1)
              IconButton(
                icon: const Icon(LucideIcons.trash2,
                    size: 18, color: NeoColors.red),
                onPressed: () => _deleteWallet(w),
              ),
          ],
        ),
      ),
    );
  }
}