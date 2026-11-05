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
    // Mendapatkan tinggi gesture bar Android agar navbar tidak tenggelam
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      floatingActionButton: _index == 0
          ? Padding(
              // FAB digeser ke atas menyesuaikan tinggi navbar + gesture bar
              padding: EdgeInsets.only(bottom: 90 + bottomPadding),
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
          
      body: Stack(
        children: [
          // Konten Utama
          IndexedStack(index: _index, children: _screens),
          
          // NAVBAR MELAYANG (Custom Row)
          Positioned(
            left: 32, 
            right: 32,
            bottom: bottomPadding + 16, 
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                  // PERBAIKAN: Menggunakan center dan jarak statis agar tidak "LDR"
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavItem(0, Icons.grid_view_rounded, l10n.translate('dashboard')),
                      const SizedBox(width: 16), // Jarak antar menu
                      _buildNavItem(1, Icons.insert_chart_rounded, l10n.translate('analytics')),
                      const SizedBox(width: 16), // Jarak antar menu
                      _buildNavItem(2, Icons.description, l10n.translate('reports')),
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

  // Widget custom untuk setiap ikon di navbar
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _index == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected ? const Color(0xFF10B981) : Colors.grey.shade500;
    
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5)) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: color, 
                fontSize: 10, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ],
        ),
      ),
    );
  }
}