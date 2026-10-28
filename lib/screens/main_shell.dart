import 'dart:ui';
import 'package:flutter/material.dart';
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

  // Fungsi untuk membuka form dari luar Dashboard
  void _openAddScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Agar transparan tembus ke bawah
      body: IndexedStack(index: _index, children: _screens),
      
      // FAB Dipindah ke sini agar tidak tertutup bottom nav
      floatingActionButton: _index == 0 
          ? FloatingActionButton(
              onPressed: _openAddScreen,
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : null,

      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1E1E1E).withValues(alpha: 0.9) 
                  : Colors.white.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                  width: 1,
                )
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              indicatorColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded, color: Colors.grey),
                  selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF10B981)),
                  label: 'Dasbor',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insert_chart_outlined_rounded, color: Colors.grey),
                  selectedIcon: Icon(Icons.insert_chart_rounded, color: Color(0xFF10B981)),
                  label: 'Analisis',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.description, color: Color(0xFF10B981)),
                  label: 'Laporan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}