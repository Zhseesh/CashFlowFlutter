import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/cashflow_repository.dart';
import '../models/category.dart';
import '../theme/neo_theme.dart';
import '../utils/app_events.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_dialog.dart';
import '../widgets/neo_fab.dart';
import '../widgets/neo_input.dart';
import '../widgets/neo_skeleton.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});
  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
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

    final name = await showNeoDialog<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoDialogTitle(existing == null
              ? 'Tambah Kategori'
              : 'Edit Kategori'),
          NeoInput(
            controller: ctrl,
            label: 'Nama Kategori',
          ),
          NeoDialogActions(
            children: [
              NeoButton(
                label: 'Batal',
                variant: NeoButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
              NeoButton(
                label: 'Simpan',
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    if (existing == null) {
      await _repo.insertCategory(Category(
          name: name, type: type, iconName: iconName, colorHex: colorHex));
    } else {
      await _repo.updateCategory(Category(
          id: existing.id,
          name: name,
          type: type,
          iconName: iconName,
          colorHex: colorHex));
    }
    _load();
    AppEvents.notify();
  }

  Future<void> _deleteCategory(Category c) async {
    final ok = await showNeoDialog<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NeoDialogTitle('Hapus Kategori?'),
          Text(
            'Kategori "${c.name}" akan dihapus. Transaksi lama tidak akan terpengaruh.',
            style: NeoText.body(13, color: Neo.ink(context)),
          ),
          NeoDialogActions(
            children: [
              NeoButton(
                label: 'Batal',
                variant: NeoButtonVariant.secondary,
                onPressed: () => Navigator.pop(context, false),
              ),
              NeoButton(
                label: 'Hapus',
                variant: NeoButtonVariant.danger,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
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
    final ink = Neo.ink(context);
    final color = type == 'INCOME' ? NeoColors.lime : NeoColors.pink;

    if (categories.isEmpty) {
      return Center(
        child: Text('Belum ada kategori.',
            style: NeoText.body(13, color: ink.withValues(alpha: 0.5))),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = categories[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Neo.paper(context),
            borderRadius: BorderRadius.circular(NeoRadius.reg),
            border: NeoBorders.reg(ink),
            boxShadow: NeoShadows.sm(ink),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  border: NeoBorders.thin(ink),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type == 'INCOME'
                      ? LucideIcons.arrowDownLeft
                      : LucideIcons.arrowUpRight,
                  size: 18,
                  color: NeoColors.inkLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(c.name,
                    style:
                        NeoText.body(14, weight: FontWeight.w700, color: ink)),
              ),
              IconButton(
                icon: Icon(LucideIcons.pencil,
                    size: 18, color: ink.withValues(alpha: 0.7)),
                onPressed: () => _showFormDialog(existing: c, type: type),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2,
                    size: 18, color: NeoColors.red),
                onPressed: () => _deleteCategory(c),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kategori Kustom',
            style: NeoText.display(18, color: ink)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Neo.paper(context),
              borderRadius: BorderRadius.circular(NeoRadius.reg),
              border: NeoBorders.reg(ink),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: NeoColors.yellow,
                borderRadius: BorderRadius.circular(10),
                border: NeoBorders.thin(ink),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: NeoColors.inkLight,
              unselectedLabelColor: ink.withValues(alpha: 0.6),
              labelStyle: NeoText.label(11, color: NeoColors.inkLight),
              unselectedLabelStyle: NeoText.label(11),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'PEMASUKAN'),
                Tab(text: 'PENGELUARAN'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: const NeoSkeletonList(count: 15))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_incomeCategories, 'INCOME'),
                _buildList(_expenseCategories, 'EXPENSE'),
              ],
            ),
      floatingActionButton: NeoFab(
        icon: LucideIcons.plus,
        color: NeoColors.yellow,
        onTap: () {
          final type = _tabController.index == 0 ? 'INCOME' : 'EXPENSE';
          _showFormDialog(type: type);
        },
      ),
    );
  }
}