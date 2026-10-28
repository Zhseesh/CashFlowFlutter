import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/cashflow_repository.dart';
import 'screens/main_shell.dart';
import 'utils/app_state.dart';
import 'utils/app_theme.dart';
import 'utils/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  // Load preferensi tema
  await ThemeManager.load();

  // Inisialisasi Tabungan Pertama
  final repo = CashFlowRepository();
  final wallets = await repo.getWallets();
  if (wallets.isNotEmpty) {
    AppState.activeWallet.value = wallets.first;
  }

  // Set status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, 
  ));
  
  runApp(const CashFlowApp());
}

class CashFlowApp extends StatelessWidget {
  const CashFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan tema secara global
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Cash Flow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,       // Panggil tema Light
          darkTheme: AppTheme.dark,    // Panggil tema Dark
          themeMode: mode,             // Terapkan mode (System/Light/Dark)
          home: const MainShell(),
        );
      },
    );
  }
}