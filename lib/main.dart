import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/database_helper.dart';
import 'data/repository.dart';
import 'state/cashflow_controller.dart';
import 'state/controller_scope.dart';
import 'theme.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final controller =
      CashFlowController(CashFlowRepository(DatabaseHelper.instance));
  runApp(CashFlowApp(controller: controller));
  controller.load();
}

class CashFlowApp extends StatelessWidget {
  const CashFlowApp({super.key, required this.controller});

  final CashFlowController controller;

  @override
  Widget build(BuildContext context) {
    return ControllerScope(
      controller: controller,
      child: MaterialApp(
        title: 'Cash Flow',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeShell(),
      ),
    );
  }
}
