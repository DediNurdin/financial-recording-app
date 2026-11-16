import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../models/transfer_model.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// wallets with computed balance; when [until] is given only rows
  /// dated before it are counted (balance as of that date)
  Future<List<WalletModel>> getAllWithBalance({DateTime? until}) async {
    final cond = until == null ? '' : 'AND date < ?';
    final args = until == null
        ? const <Object?>[]
        : List<Object?>.filled(3, until.millisecondsSinceEpoch);
    final rows = await (await _db).rawQuery('''
      SELECT w.*, w.initial_balance
        + COALESCE((SELECT SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END)
                    FROM transactions WHERE wallet_id = w.id $cond), 0)
        + COALESCE((SELECT SUM(amount) FROM transfers
                    WHERE to_wallet_id = w.id $cond), 0)
        - COALESCE((SELECT SUM(amount) FROM transfers
                    WHERE from_wallet_id = w.id $cond), 0) AS balance
      FROM wallets w
      ORDER BY w.id
    ''', args);
    return rows.map(WalletModel.fromMap).toList();
  }

  Future<int> insert(WalletModel w) async =>
      (await _db).insert('wallets', w.toMap());

  Future<void> update(WalletModel w) async => (await _db).update(
    'wallets',
    w.toMap(),
    where: 'id = ?',
    whereArgs: [w.id],
  );

  Future<bool> isUsed(int id) async {
    final rows = await (await _db).rawQuery(
      '''
      SELECT 1 FROM transactions WHERE wallet_id = ?
      UNION ALL
      SELECT 1 FROM transfers WHERE from_wallet_id = ? OR to_wallet_id = ?
      LIMIT 1
    ''',
      [id, id, id],
    );
    return rows.isNotEmpty;
  }

  Future<void> delete(int id) async =>
      (await _db).delete('wallets', where: 'id = ?', whereArgs: [id]);

  Future<List<TransferModel>> transfersByWallet(int walletId) async {
    final rows = await (await _db).rawQuery(
      '''
      SELECT x.*, f.name AS from_name, t.name AS to_name
      FROM transfers x
      JOIN wallets f ON f.id = x.from_wallet_id
      JOIN wallets t ON t.id = x.to_wallet_id
      WHERE x.from_wallet_id = ? OR x.to_wallet_id = ?
      ORDER BY x.date DESC, x.id DESC
    ''',
      [walletId, walletId],
    );
    return rows.map(TransferModel.fromMap).toList();
  }

  Future<int> insertTransfer(TransferModel t) async =>
      (await _db).insert('transfers', t.toMap());

  Future<void> updateTransfer(TransferModel t) async => (await _db).update(
    'transfers',
    t.toMap(),
    where: 'id = ?',
    whereArgs: [t.id],
  );

  Future<void> deleteTransfer(int id) async =>
      (await _db).delete('transfers', where: 'id = ?', whereArgs: [id]);
}
