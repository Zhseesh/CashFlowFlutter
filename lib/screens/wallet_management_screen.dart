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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Tabungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // Tambahkan padding bawah agar tidak tertutup FAB
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _wallets.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      ),
                      itemBuilder: (context, i) {
                        final w = _wallets[i];
                        final isActive = AppState.activeWallet.value?.id == w.id;
                        
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
                            'Dibuat: ${formatDate(DateTime.fromMillisecondsSinceEpoch(w.createdAt))}',
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
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Jarak aman untuk FAB
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
        label: const Text('Tabungan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}