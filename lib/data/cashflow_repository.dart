import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../models/category.dart';
import '../models/transaction.dart';
import 'database_helper.dart';

class CashFlowRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Category>> getCategories({String? type}) async {
    final db = await _helper.db;
    final rows = await db.query(
      'categories',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
      orderBy: 'name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<List<TransactionRecord>> getTransactions({
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    final db = await _helper.db;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) { where.add('date_millis >= ?'); args.add(from.millisecondsSinceEpoch); }
    if (to != null) { where.add('date_millis <= ?'); args.add(to.millisecondsSinceEpoch); }
    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date_millis DESC, id DESC',
      limit: limit,
    );
    return rows.map(TransactionRecord.fromMap).toList();
  }

  Future<int> insertTransaction(TransactionRecord t) async {
    final db = await _helper.db;
    return db.insert('transactions', t.toMap());
  }

  Future<int> updateTransaction(TransactionRecord t) async {
    final db = await _helper.db;
    return db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _helper.db;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getSaldoAwal() async {
    final db = await _helper.db;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: ['saldo_awal']);
    if (rows.isEmpty) return 0;
    return double.tryParse(rows.first['value'] as String) ?? 0;
  }

  Future<void> setSaldoAwal(double value) async {
    final db = await _helper.db;
    await db.insert(
      'settings',
      {'key': 'saldo_awal', 'value': value.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> totalByType(String type, {DateTime? from, DateTime? to}) async {
    final db = await _helper.db;
    final where = <String>['type = ?'];
    final args = <Object?>[type];
    if (from != null) { where.add('date_millis >= ?'); args.add(from.millisecondsSinceEpoch); }
    if (to != null) { where.add('date_millis <= ?'); args.add(to.millisecondsSinceEpoch); }
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE ${where.join(' AND ')}',
      args,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getCurrentBalance() async {
    final awal = await getSaldoAwal();
    final income = await totalByType('INCOME');
    final expense = await totalByType('EXPENSE');
    return awal + income - expense;
  }

  Future<Map<int, ({double income, double expense})>> monthlyTotals(int year) async {
    final db = await _helper.db;
    final start = DateTime(year, 1, 1).millisecondsSinceEpoch;
    final end = DateTime(year + 1, 1, 1).millisecondsSinceEpoch;
    final rows = await db.rawQuery('''
      SELECT strftime('%m', date_millis/1000, 'unixepoch', 'localtime') AS m,
             type, COALESCE(SUM(amount),0) AS total
      FROM transactions
      WHERE date_millis >= ? AND date_millis < ?
      GROUP BY m, type
    ''', [start, end]);
    final map = <int, ({double income, double expense})>{};
    for (int i = 1; i <= 12; i++) { map[i] = (income: 0.0, expense: 0.0); }
    for (final r in rows) {
      final m = int.parse(r['m'] as String);
      final t = r['type'] as String;
      final v = (r['total'] as num).toDouble();
      final prev = map[m] ?? (income: 0.0, expense: 0.0);
      map[m] = t == 'INCOME'
          ? (income: prev.income + v, expense: prev.expense)
          : (income: prev.income, expense: prev.expense + v);
    }
    return map;
  }

  Future<List<({String category, double total})>> categoryBreakdown(
    String type, {DateTime? from, DateTime? to}) async {
    final db = await _helper.db;
    final where = <String>['type = ?'];
    final args = <Object?>[type];
    if (from != null) { where.add('date_millis >= ?'); args.add(from.millisecondsSinceEpoch); }
    if (to != null) { where.add('date_millis <= ?'); args.add(to.millisecondsSinceEpoch); }
    final rows = await db.rawQuery('''
      SELECT category_name, COALESCE(SUM(amount),0) AS total
      FROM transactions
      WHERE ${where.join(' AND ')}
      GROUP BY category_name
      ORDER BY total DESC
    ''', args);
    return rows
        .map((r) => (category: r['category_name'] as String, total: (r['total'] as num).toDouble()))
        .toList();
  }

  Future<void> restoreTransactions(List<TransactionRecord> list) async {
    final db = await _helper.db;
    await db.transaction((txn) async {
      for (final t in list) {
        final map = t.toMap()..remove('id');
        await txn.insert('transactions', map);
      }
    });
  }
}