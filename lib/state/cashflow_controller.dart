// Category bentrok dengan anotasi Category milik Flutter.
import 'package:flutter/foundation.dart' hide Category;

import '../data/repository.dart';
import '../models/models.dart';

/// State aplikasi (setara CashFlowViewModel): data dasbor, riwayat, analisis.
class CashFlowController extends ChangeNotifier {
  CashFlowController(this.repo);
  final CashFlowRepository repo;

  bool loading = true;
  String? loadError;

  List<Category> categories = [];
  List<CashTransaction> allTransactions = [];

  // Dasbor
  double balance = 0;
  double monthIncome = 0;
  double monthExpense = 0;
  List<MonthTotal> trend = [];

  // Analisis
  DateTime analyticsMonth = DateTime(DateTime.now().year, DateTime.now().month);
  TxType breakdownType = TxType.expense;
  double analyticsIncome = 0;
  double analyticsExpense = 0;
  List<MonthTotal> analyticsSeries = [];
  List<CategoryTotal> breakdown = [];

  List<CashTransaction> get recent => allTransactions.take(5).toList();

  Category? categoryFor(CashTransaction tx) {
    if (tx.categoryId != null) {
      for (final c in categories) {
        if (c.id == tx.categoryId) return c;
      }
    }
    for (final c in categories) {
      if (c.name == tx.categoryName && c.type == tx.type) return c;
    }
    return null;
  }

  Future<void> load() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      final monthEnd = DateTime(now.year, now.month + 1);

      categories = await repo.categories();
      allTransactions = await repo.transactions();
      balance = await repo.currentBalance();
      final t = await repo.totals(monthStart, monthEnd);
      monthIncome = t.income;
      monthExpense = t.expense;
      trend = await repo.monthlyTotals(monthStart, 6);
      await _loadAnalytics();
      loadError = null;
    } catch (e) {
      loadError = '$e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _loadAnalytics() async {
    final m = analyticsMonth;
    final from = DateTime(m.year, m.month);
    final to = DateTime(m.year, m.month + 1);
    final t = await repo.totals(from, to);
    analyticsIncome = t.income;
    analyticsExpense = t.expense;
    analyticsSeries = await repo.monthlyTotals(m, 6);
    breakdown = await repo.categoryBreakdown(breakdownType, from, to);
  }

  Future<void> setAnalyticsMonth(DateTime month) async {
    analyticsMonth = DateTime(month.year, month.month);
    await _loadAnalytics();
    notifyListeners();
  }

  Future<void> setBreakdownType(TxType type) async {
    breakdownType = type;
    await _loadAnalytics();
    notifyListeners();
  }

  Future<void> saveTransaction(CashTransaction tx) async {
    if (tx.id == null) {
      await repo.addTransaction(tx);
    } else {
      await repo.updateTransaction(tx);
    }
    await load();
  }

  Future<void> deleteTransaction(int id) async {
    await repo.deleteTransaction(id);
    await load();
  }

  Future<ImportResult> importBackup(BackupData data,
      {required bool replace}) async {
    final r = await repo.importBackup(data, replace: replace);
    await load();
    return r;
  }
}
