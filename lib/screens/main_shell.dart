import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      // FAB diletakkan di sini dan digeser ke atas (bottom: 90) agar tidak menabrak navbar
      floatingActionButton: _index == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton(
                onPressed: _openAddScreen,
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
          
      // Body menggunakan Stack agar Navbar bisa melayang di atas konten
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          
          // Navbar Melayang (Telegram Style)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20, // Jarak dari bawah layar
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF1E1E1E).withValues(alpha: 0.85) 
                        : Colors.white.withValues(alpha: 0.85),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200, 
                      width: 1
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    height: 70,
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    indicatorColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.grid_view_rounded, color: Colors.grey),
                        selectedIcon: const Icon(Icons.grid_view_rounded, color: Color(0xFF10B981)),
                        label: l10n.translate('dashboard'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.insert_chart_outlined_rounded, color: Colors.grey),
                        selectedIcon: const Icon(Icons.insert_chart_rounded, color: Color(0xFF10B981)),
                        label: l10n.translate('analytics'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.description_outlined, color: Colors.grey),
                        selectedIcon: const Icon(Icons.description, color: Color(0xFF10B981)),
                        label: l10n.translate('reports'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}