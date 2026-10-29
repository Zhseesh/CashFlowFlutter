import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'database_helper.dart';

class CashFlowRepository {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  // ── WALLET METHODS ──────────────────────────────────────
  Future<List<Wallet>> getWallets() async {
    final db = await _helper.db;
    final rows = await db.query('wallets', orderBy: 'created_at ASC');
    return rows.map(Wallet.fromMap).toList();
  }

  Future<int> insertWallet(Wallet wallet) async {
    final db = await _helper.db;
    return db.insert('wallets', wallet.toMap());
  }

  Future<void> deleteWallet(int id) async {
    final db = await _helper.db;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateWalletName(int id, String newName) async {
    final db = await _helper.db;
    await db.update('wallets', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  // ── BUDGET METHODS ──────────────────────────────────────
  Future<List<Budget>> getBudgets(int walletId) async {
    final db = await _helper.db;
    final rows = await db.query('budgets', where: 'wallet_id = ?', whereArgs: [walletId]);
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> setBudget(Budget b) async {
    final db = await _helper.db;
    await db.insert(
      'budgets',
      b.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget(int id) async {
    final db = await _helper.db;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getSpentForCategory({
    required int walletId,
    required String categoryName,
    required int month,
    required int year,
  }) async {
    final db = await _helper.db;
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE wallet_id = ? AND category_name = ? AND type = "EXPENSE" AND date_millis >= ? AND date_millis <= ?',
      [walletId, categoryName, start, end],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ── CATEGORY METHODS ────────────────────────────────────
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

  Future<int> insertCategory(Category c) async {
    final db = await _helper.db;
    return db.insert('categories', c.toMap());
  }

  Future<void> updateCategory(Category c) async {
    final db = await _helper.db;
    await db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await _helper.db;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── TRANSACTION METHODS ─────────────────────────────────
  Future<List<TransactionRecord>> getTransactions({
    required int walletId,
    DateTime? from,
    DateTime? to,
    int limit = 100,
    String? searchQuery,
  }) async {
    final db = await _helper.db;
    final where = <String>['wallet_id = ?'];
    final args = <Object?>[walletId];
    
    if (from != null) { where.add('date_millis >= ?'); args.add(from.millisecondsSinceEpoch); }
    if (to != null) { where.add('date_millis <= ?'); args.add(to.millisecondsSinceEpoch); }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(title LIKE ? OR note LIKE ?)');
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }

    final rows = await db.query(
      'transactions',
      where: where.join(' AND '),
      whereArgs: args,
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

  // ── SETTINGS / SALDO ────────────────────────────────────
  Future<double> getSaldoAwal(int walletId) async {
    final db = await _helper.db;
    final key = 'saldo_awal_$walletId'; 
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return 0;
    return double.tryParse(rows.first['value'] as String) ?? 0;
  }

  Future<void> setSaldoAwal(int walletId, double value) async {
    final db = await _helper.db;
    final key = 'saldo_awal_$walletId';
    await db.insert(
      'settings',
      {'key': key, 'value': value.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── AGGREGATIONS ────────────────────────────────────────
  Future<double> totalByType(String type, {required int walletId, DateTime? from, DateTime? to}) async {
    final db = await _helper.db;
    final where = <String>['type = ?', 'wallet_id = ?'];
    final args = <Object?>[type, walletId];
    if (from != null) { where.add('date_millis >= ?'); args.add(from.millisecondsSinceEpoch); }
    if (to != null) { where.add('date_millis <= ?'); args.add(to.millisecondsSinceEpoch); }
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE ${where.join(' AND ')}',
      args,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getCurrentBalance(int walletId) async {
    final awal = await getSaldoAwal(walletId);
    final income = await totalByType('INCOME', walletId: walletId);
    final expense = await totalByType('EXPENSE', walletId: walletId);
    return awal + income - expense;
  }

  Future<Map<int, ({double income, double expense})>> monthlyTotals(int year, {required int walletId}) async {
    final db = await _helper.db;
    final start = DateTime(year, 1, 1).millisecondsSinceEpoch;
    final end = DateTime(year + 1, 1, 1).millisecondsSinceEpoch;
    final rows = await db.rawQuery('''
      SELECT strftime('%m', date_millis/1000, 'unixepoch', 'localtime') AS m,
             type, COALESCE(SUM(amount),0) AS total
      FROM transactions
      WHERE date_millis >= ? AND date_millis < ? AND wallet_id = ?
      GROUP BY m, type
    ''', [start, end, walletId]);
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
    String type, {required int walletId, DateTime? from, DateTime? to}) async {
    final db = await _helper.db;
    final where = <String>['type = ?', 'wallet_id = ?'];
    final args = <Object?>[type, walletId];
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

  Future<void> restoreTransactions(List<TransactionRecord> list, {required int walletId}) async {
    final db = await _helper.db;
    await db.transaction((txn) async {
      for (final t in list) {
        final map = t.toMap()..remove('id');
        map['wallet_id'] = walletId;
        await txn.insert('transactions', map);
      }
    });
  }
}