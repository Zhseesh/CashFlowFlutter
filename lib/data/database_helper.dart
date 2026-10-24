import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Akses SQLite langsung (tanpa ORM): kueri SQL, indeks, dan transaksi atomik.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'cashflow.db';
  static const _dbVersion = 1;

  Future<Database>? _opening;
  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  static const _seed = <List<String>>[
    ['Gaji', 'INCOME', 'payments', '#10B981'],
    ['Usaha', 'INCOME', 'storefront', '#14B8A6'],
    ['Investasi', 'INCOME', 'trending_up', '#6366F1'],
    ['Bonus', 'INCOME', 'card_giftcard', '#F59E0B'],
    ['Pemasukan Lainnya', 'INCOME', 'category', '#64748B'],
    ['Makanan', 'EXPENSE', 'restaurant', '#F97316'],
    ['Transportasi', 'EXPENSE', 'directions_car', '#0EA5E9'],
    ['Tagihan', 'EXPENSE', 'receipt_long', '#E11D48'],
    ['Belanja', 'EXPENSE', 'shopping_bag', '#EC4899'],
    ['Kesehatan', 'EXPENSE', 'medical_services', '#EF4444'],
    ['Hiburan', 'EXPENSE', 'movie', '#8B5CF6'],
    ['Pendidikan', 'EXPENSE', 'school', '#3B82F6'],
    ['Pengeluaran Lainnya', 'EXPENSE', 'more_horiz', '#64748B'],
  ];

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        category_name TEXT NOT NULL,
        date_millis INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_tx_date ON transactions(date_millis)');
    await db.execute('CREATE INDEX idx_tx_type ON transactions(type)');
    await db.execute(
        'CREATE INDEX idx_tx_category ON transactions(category_id)');

    for (final s in _seed) {
      await db.insert('categories', {
        'name': s[0],
        'type': s[1],
        'icon_name': s[2],
        'color_hex': s[3],
      });
    }
  }

  // ---------------------------------------------------------------- kategori

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'type ASC, id ASC');
    return rows.map(Category.fromMap).toList();
  }

  // --------------------------------------------------------------- transaksi

  Future<int> insertTransaction(CashTransaction tx) async {
    final db = await database;
    return db.insert('transactions', tx.toMap()..remove('id'));
  }

  Future<void> updateTransaction(CashTransaction tx) async {
    final db = await database;
    await db.update(
      'transactions',
      tx.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CashTransaction>> getTransactions({
    int? from,
    int? toExclusive,
    bool ascending = false,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object>[];
    if (from != null) {
      where.add('date_millis >= ?');
      args.add(from);
    }
    if (toExclusive != null) {
      where.add('date_millis < ?');
      args.add(toExclusive);
    }
    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: ascending
          ? 'date_millis ASC, id ASC'
          : 'date_millis DESC, id DESC',
    );
    return rows.map(CashTransaction.fromMap).toList();
  }

  // ----------------------------------------------------------------- agregat

  /// Saldo (pemasukan - pengeluaran) seluruh transaksi sebelum [millis].
  Future<double> balanceBefore(int millis) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount ELSE -amount END), 0) AS b
      FROM transactions
      WHERE date_millis < ?
    ''', [millis]);
    return (rows.first['b'] as num).toDouble();
  }

  /// Total per tipe pada rentang [from, toExclusive).
  Future<({double income, double expense})> sumByType(
      int from, int toExclusive) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT type, COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE date_millis >= ? AND date_millis < ?
      GROUP BY type
    ''', [from, toExclusive]);
    var income = 0.0;
    var expense = 0.0;
    for (final r in rows) {
      final total = (r['total'] as num).toDouble();
      if (r['type'] == 'INCOME') {
        income = total;
      } else {
        expense = total;
      }
    }
    return (income: income, expense: expense);
  }

  /// Baris: ym ('2026-10'), type, total. GROUP BY strftime per bulan (waktu lokal).
  Future<List<Map<String, Object?>>> monthlyRows(
      int from, int toExclusive) async {
    final db = await database;
    return db.rawQuery('''
      SELECT strftime('%Y-%m', date_millis / 1000, 'unixepoch', 'localtime') AS ym,
             type,
             SUM(amount) AS total
      FROM transactions
      WHERE date_millis >= ? AND date_millis < ?
      GROUP BY ym, type
    ''', [from, toExclusive]);
  }

  Future<List<CategoryTotal>> categoryBreakdown(
      TxType type, int from, int toExclusive) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT t.category_name AS name,
             COALESCE(c.color_hex, '#64748B') AS color,
             COALESCE(c.icon_name, 'category') AS icon,
             SUM(t.amount) AS total,
             COUNT(*) AS cnt
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = ? AND t.date_millis >= ? AND t.date_millis < ?
      GROUP BY t.category_name
      ORDER BY total DESC
    ''', [type.dbValue, from, toExclusive]);
    return rows
        .map((r) => CategoryTotal(
              name: r['name'] as String,
              colorHex: r['color'] as String,
              iconName: r['icon'] as String,
              total: (r['total'] as num).toDouble(),
              count: r['cnt'] as int,
            ))
        .toList();
  }

  // --------------------------------------------------- impor / pemulihan data

  /// Mengganti seluruh isi database dalam satu transaksi atomik.
  Future<ImportResult> replaceAll(BackupData data) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('categories');
      for (final c in data.categories) {
        await txn.insert('categories', c.toMap());
      }
      for (final t in data.transactions) {
        await txn.insert('transactions', t.toMap());
      }
      return ImportResult(
        categories: data.categories.length,
        transactions: data.transactions.length,
      );
    });
  }

  /// Menumpuk data cadangan ke database yang ada (duplikat dilewati).
  Future<ImportResult> mergeData(BackupData data) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = (await txn.query('categories'))
          .map(Category.fromMap)
          .toList();
      final idMap = <int, int>{};
      var addedCategories = 0;

      for (final c in data.categories) {
        final match = existing.where(
          (e) => e.name == c.name && e.type == c.type,
        );
        if (match.isNotEmpty) {
          idMap[c.id!] = match.first.id!;
        } else {
          final newId =
              await txn.insert('categories', c.toMap()..remove('id'));
          idMap[c.id!] = newId;
          existing.add(Category(
            id: newId,
            name: c.name,
            type: c.type,
            iconName: c.iconName,
            colorHex: c.colorHex,
          ));
          addedCategories++;
        }
      }

      var inserted = 0;
      var skipped = 0;
      for (final t in data.transactions) {
        final dup = await txn.rawQuery('''
          SELECT COUNT(*) AS n FROM transactions
          WHERE title = ? AND amount = ? AND type = ?
            AND date_millis = ? AND category_name = ?
        ''', [t.title, t.amount, t.type.dbValue, t.dateMillis, t.categoryName]);
        if ((dup.first['n'] as int) > 0) {
          skipped++;
          continue;
        }
        final map = t.toMap()..remove('id');
        map['category_id'] = t.categoryId == null ? null : idMap[t.categoryId];
        await txn.insert('transactions', map);
        inserted++;
      }

      return ImportResult(
        categories: addedCategories,
        transactions: inserted,
        skipped: skipped,
      );
    });
  }
}
