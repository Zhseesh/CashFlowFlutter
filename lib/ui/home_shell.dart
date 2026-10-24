import 'package:flutter/material.dart';

import '../state/controller_scope.dart';
import 'add_transaction_sheet.dart';
import 'analytics_page.dart';
import 'dashboard_page.dart';
import 'export_page.dart';
import 'transactions_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);

    if (c.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (c.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gagal memuat data.'),
                const SizedBox(height: 8),
                Text(c.loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: c.load, child: const Text('Coba lagi')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(onSeeAll: () => setState(() => _index = 1)),
          const TransactionsPage(),
          const AnalyticsPage(),
          const ExportPage(),
        ],
      ),
      floatingActionButton: _index <= 1
          ? FloatingActionButton.extended(
              onPressed: () => showTransactionSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dasbor'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Riwayat'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Analisis'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded),
              label: 'Data'),
        ],
      ),
    );
  }
}
