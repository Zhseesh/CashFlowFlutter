import '../models/models.dart';
import 'database_helper.dart';

class CashFlowRepository {
  CashFlowRepository(this._db);
  final DatabaseHelper _db;

  Future<List<Category>> categories() => _db.getCategories();

  Future<void> addTransaction(CashTransaction tx) =>
      _db.insertTransaction(tx);

  Future<void> updateTransaction(CashTransaction tx) =>
      _db.updateTransaction(tx);

  Future<void> deleteTransaction(int id) => _db.deleteTransaction(id);

  /// Rentang [from, toExclusive); null berarti tanpa batas.
  Future<List<CashTransaction>> transactions({
    DateTime? from,
    DateTime? toExclusive,
    bool ascending = false,
  }) =>
      _db.getTransactions(
        from: from?.millisecondsSinceEpoch,
        toExclusive: toExclusive?.millisecondsSinceEpoch,
        ascending: ascending,
      );

  Future<double> balanceBefore(DateTime t) =>
      _db.balanceBefore(t.millisecondsSinceEpoch);

  Future<double> currentBalance() => balanceBefore(DateTime(9999));

  Future<({double income, double expense})> totals(
          DateTime from, DateTime toExclusive) =>
      _db.sumByType(
          from.millisecondsSinceEpoch, toExclusive.millisecondsSinceEpoch);

  /// [count] bulan berakhir pada [endMonth] (terisi nol bila kosong).
  Future<List<MonthTotal>> monthlyTotals(DateTime endMonth, int count) async {
    final start = DateTime(endMonth.year, endMonth.month - count + 1);
    final end = DateTime(endMonth.year, endMonth.month + 1);
    final rows = await _db.monthlyRows(
        start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);

    final income = <String, double>{};
    final expense = <String, double>{};
    for (final r in rows) {
      final ym = r['ym'] as String;
      final total = (r['total'] as num).toDouble();
      if (r['type'] == 'INCOME') {
        income[ym] = total;
      } else {
        expense[ym] = total;
      }
    }

    return List.generate(count, (i) {
      final m = DateTime(start.year, start.month + i);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      return MonthTotal(
        month: m,
        income: income[key] ?? 0,
        expense: expense[key] ?? 0,
      );
    });
  }

  Future<List<CategoryTotal>> categoryBreakdown(
          TxType type, DateTime from, DateTime toExclusive) =>
      _db.categoryBreakdown(type, from.millisecondsSinceEpoch,
          toExclusive.millisecondsSinceEpoch);

  Future<BackupData> exportBackup() async => BackupData(
        categories: await _db.getCategories(),
        transactions: await _db.getTransactions(ascending: true),
        exportedAt: DateTime.now().toIso8601String(),
      );

  Future<ImportResult> importBackup(BackupData data,
          {required bool replace}) =>
      replace ? _db.replaceAll(data) : _db.mergeData(data);
}
