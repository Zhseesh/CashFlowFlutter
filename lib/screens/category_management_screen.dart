import 'package:flutter/material.dart';
import '../data/cashflow_repository.dart';
import '../models/category.dart';
import '../utils/app_events.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  final _repo = CashFlowRepository();
  late TabController _tabController;
  
  List<Category> _incomeCategories = [];
  List<Category> _expenseCategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final inc = await _repo.getCategories(type: 'INCOME');
    final exp = await _repo.getCategories(type: 'EXPENSE');
    if (!mounted) return;
    setState(() {
      _incomeCategories = inc;
      _expenseCategories = exp;
      _loading = false;
    });
  }

  Future<void> _showFormDialog({Category? existing, required String type}) async {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    final colorHex = type == 'INCOME' ? '#10B981' : '#EF4444';
    final iconName = type == 'INCOME' ? 'salary' : 'food';

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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

    if (existing == null) {
      await _repo.insertCategory(Category(name: name, type: type, iconName: iconName, colorHex: colorHex));
    } else {
      await _repo.updateCategory(Category(id: existing.id, name: name, type: type, iconName: iconName, colorHex: colorHex));
    }
    
    _load();
    AppEvents.notify();
  }

  Future<void> _deleteCategory(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "${c.name}" akan dihapus. Transaksi lama tidak akan terpengaruh.'),
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

    await _repo.deleteCategory(c.id!);
    _load();
    AppEvents.notify();
  }

  Widget _buildList(List<Category> categories, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = type == 'INCOME' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    if (categories.isEmpty) {
      return Center(
        child: Text('Belum ada kategori.', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = categories[i];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(type == 'INCOME' ? Icons.south_west : Icons.north_east, color: color, size: 18),
            ),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: Colors.grey,
                  onPressed: () => _showFormDialog(existing: c, type: type),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.grey,
                  onPressed: () => _deleteCategory(c),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // PERBAIKAN: Mencegah FAB memantul saat keyboard dialog muncul
      resizeToAvoidBottomInset: false,
      
      appBar: AppBar(
        title: const Text('Kategori Kustom', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_incomeCategories, 'INCOME'),
                _buildList(_expenseCategories, 'EXPENSE'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0 ? 'INCOME' : 'EXPENSE';
          _showFormDialog(type: type);
        },
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: const Color(0xFF10B981),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}