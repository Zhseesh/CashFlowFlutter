import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static const _dbName = 'cashflow.db';
  static const _dbVersion = 5; 
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
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    
    batch.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

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
        wallet_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        category_name TEXT NOT NULL,
        date_millis INTEGER NOT NULL,
        note TEXT,
        attachment_paths TEXT,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY(wallet_id) REFERENCES wallets(id) ON DELETE CASCADE
      )
    ''');

    // Tabel Budgets Baru
    batch.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wallet_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        FOREIGN KEY(wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
        UNIQUE(wallet_id, category_name)
      )
    ''');

    batch.execute('CREATE INDEX idx_tx_date ON transactions(date_millis)');
    batch.execute('CREATE INDEX idx_tx_wallet ON transactions(wallet_id)');
    
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

    await db.insert('wallets', {
      'name': 'Dompet Utama',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN attachment_path TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      final defaultWalletId = await db.insert('wallets', {
        'name': 'Dompet Utama',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      await db.execute('ALTER TABLE transactions ADD COLUMN wallet_id INTEGER');
      await db.update('transactions', {'wallet_id': defaultWalletId});
      await db.execute('CREATE INDEX idx_tx_wallet ON transactions(wallet_id)');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE transactions ADD COLUMN attachment_paths TEXT');
      final oldData = await db.query('transactions', where: 'attachment_path IS NOT NULL');
      for (var row in oldData) {
        final oldPath = row['attachment_path'] as String;
        final jsonStr = '["$oldPath"]'; 
        await db.update('transactions', {'attachment_paths': jsonStr}, where: 'id = ?', whereArgs: [row['id']]);
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          wallet_id INTEGER NOT NULL,
          category_name TEXT NOT NULL,
          limit_amount REAL NOT NULL,
          FOREIGN KEY(wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
          UNIQUE(wallet_id, category_name)
        )
      ''');
    }
  }
}