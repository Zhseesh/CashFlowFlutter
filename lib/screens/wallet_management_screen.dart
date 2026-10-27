import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
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
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Tabungan'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nama Tabungan'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    
    await _repo.insertWallet(Wallet(
      name: name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    _load();
    AppEvents.notify();
  }

  Future<void> _editWallet(Wallet w) async {
    final ctrl = TextEditingController(text: w.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Nama Tabungan'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nama Tabungan'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == w.name) return;
    
    await _repo.updateWalletName(w.id!, name);
    // Jika tabungan yang diedit sedang aktif, update state globalnya
    if (AppState.activeWallet.value?.id == w.id) {
      AppState.activeWallet.value = Wallet(id: w.id, name: name, createdAt: w.createdAt);
    }
    _load();
  }

  Future<void> _deleteWallet(Wallet w) async {
    if (_wallets.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa menghapus tabungan terakhir')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tabungan?'),
        content: Text('Semua transaksi di "${w.name}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Tabungan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWallet,
        icon: const Icon(Icons.add),
        label: const Text('Tabungan'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _wallets.length,
              itemBuilder: (context, i) {
                final w = _wallets[i];
                final isActive = AppState.activeWallet.value?.id == w.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isActive ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
                  child: ListTile(
                    leading: Icon(
                      isActive ? Icons.check_circle : Icons.account_balance_wallet_outlined,
                      color: isActive ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Dibuat: ${formatDate(DateTime.fromMillisecondsSinceEpoch(w.createdAt))}'),
                    onTap: () {
                      AppState.activeWallet.value = w;
                      Navigator.pop(context); // Kembali ke dashboard
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editWallet(w),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE11D48)),
                          onPressed: () => _deleteWallet(w),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}