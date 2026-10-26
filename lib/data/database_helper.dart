import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static const _dbName = 'cashflow.db';
  static const _dbVersion = 1;
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = await getDatabasesPath();
    return openDatabase(
      p.join(path, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL
      )
    ''');
    batch.execute('''
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
    batch.execute('CREATE INDEX idx_tx_date ON transactions(date_millis)');
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await batch.commit(noResult: true);

    for (final c in Category.defaults) {
      await db.insert('categories', c.toMap());
    }
  }
}