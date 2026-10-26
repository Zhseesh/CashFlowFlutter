import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'reports_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _screens = const [DashboardScreen(), AnalyticsScreen(), ReportsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dasbor'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analisis'),
          NavigationDestination(icon: Icon(Icons.file_present_outlined), selectedIcon: Icon(Icons.file_present), label: 'Laporan'),
        ],
      ),
    );
  }
}