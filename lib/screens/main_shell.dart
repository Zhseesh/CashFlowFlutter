import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../theme/neo_theme.dart';
import '../widgets/neo_navbar.dart';
import '../widgets/neo_fab.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'reports_screen.dart';
import 'transaction_form_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _screens = const [DashboardScreen(), AnalyticsScreen(), ReportsScreen()];

  void _openAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),

      // FAB Neo — hanya di tab Dashboard (index 0), duduk di atas navbar
      floatingActionButton: _index == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeoFab(
                icon: LucideIcons.plus,
                color: NeoColors.pink,
                onTap: _openAddScreen,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Navbar Neo dengan 3 tab + animasi expanding label
      bottomNavigationBar: NeoNavbar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          NeoNavItem(
            icon: LucideIcons.layoutGrid,
            label: l10n.translate('dashboard'),
          ),
          NeoNavItem(
            icon: LucideIcons.barChart3,
            label: l10n.translate('analytics'),
          ),
          NeoNavItem(
            icon: LucideIcons.fileText,
            label: l10n.translate('reports'),
          ),
        ],
      ),
    );
  }
}