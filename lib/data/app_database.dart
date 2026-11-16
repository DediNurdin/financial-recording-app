import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'default_categories.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  /// set in tests (e.g. inMemoryDatabasePath)
  static String? pathOverride;

  /// v1: categories, transactions
  /// v2: wallets, transfers, transactions.wallet_id
  static const version = 2;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path =
        pathOverride ?? p.join(await getDatabasesPath(), 'catatan_keuangan.db');
    return openDatabase(
      path,
      version: version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
    await _createWallets(db);
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        amount INTEGER NOT NULL CHECK (amount > 0),
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
        wallet_id INTEGER NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_wallet ON transactions(wallet_id)',
    );
    await _createTransfers(db);

    final batch = db.batch();
    for (final c in defaultCategories) {
      batch.insert('categories', c.toMap());
    }
    for (final w in defaultWallets) {
      batch.insert('wallets', w.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createWallets(db);
      final cashId = await db.insert('wallets', defaultWallets.first.toMap());
      for (final w in defaultWallets.skip(1)) {
        await db.insert('wallets', w.toMap());
      }
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN wallet_id INTEGER REFERENCES wallets(id)',
      );
      // existing records go to the cash wallet
      await db.update('transactions', {'wallet_id': cashId});
      await db.execute(
        'CREATE INDEX idx_transactions_wallet ON transactions(wallet_id)',
      );
      await _createTransfers(db);
    }
  }

  Future<void> _createWallets(Database db) => db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )
    ''');

  Future<void> _createTransfers(Database db) async {
    await db.execute('''
      CREATE TABLE transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_wallet_id INTEGER NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
        to_wallet_id INTEGER NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
        amount INTEGER NOT NULL CHECK (amount > 0),
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
        CHECK (from_wallet_id <> to_wallet_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_transfers_from ON transfers(from_wallet_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transfers_to ON transfers(to_wallet_id)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
