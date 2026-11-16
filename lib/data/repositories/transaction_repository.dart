import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../models/category_summary.dart';
import '../models/transaction_model.dart';
import '../models/tx_type.dart';

typedef Totals = ({int income, int expense});

class TransactionRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  static const _select = '''
    SELECT t.*, c.name AS c_name, c.icon AS c_icon, c.color AS c_color,
           w.name AS w_name
    FROM transactions t
    LEFT JOIN categories c ON c.id = t.category_id
    LEFT JOIN wallets w ON w.id = t.wallet_id
  ''';

  Future<List<TransactionModel>> getByWallet(int walletId) async {
    final rows = await (await _db).rawQuery(
      '$_select WHERE t.wallet_id = ? ORDER BY t.date DESC, t.id DESC',
      [walletId],
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  /// [start] inclusive, [end] exclusive. newest first.
  Future<List<TransactionModel>> getByRange(
    DateTime start,
    DateTime end, {
    TxType? type,
  }) async {
    final where = ['t.date >= ?', 't.date < ?'];
    final args = <Object?>[
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    ];
    if (type != null) {
      where.add('t.type = ?');
      args.add(type.value);
    }
    final rows = await (await _db).rawQuery(
      '$_select WHERE ${where.join(' AND ')} ORDER BY t.date DESC, t.id DESC',
      args,
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<int> insert(TransactionModel t) async =>
      (await _db).insert('transactions', t.toMap());

  Future<void> update(TransactionModel t) async => (await _db).update(
    'transactions',
    t.toMap(),
    where: 'id = ?',
    whereArgs: [t.id],
  );

  Future<void> delete(int id) async =>
      (await _db).delete('transactions', where: 'id = ?', whereArgs: [id]);

  /// totals in range, or all time when no range given
  Future<Totals> totals({DateTime? start, DateTime? end}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (start != null) {
      where.add('date >= ?');
      args.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      where.add('date < ?');
      args.add(end.millisecondsSinceEpoch);
    }
    final rows = await (await _db).rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS expense
      FROM transactions
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
    ''', args);
    final r = rows.first;
    return (
      income: (r['income'] as num).toInt(),
      expense: (r['expense'] as num).toInt(),
    );
  }

  Future<List<CategorySummary>> categorySummary(
    DateTime start,
    DateTime end,
    TxType type,
  ) async {
    final rows = await (await _db).rawQuery(
      '''
      SELECT c.id, c.name, c.icon, c.color,
             SUM(t.amount) AS total, COUNT(t.id) AS cnt
      FROM transactions t
      JOIN categories c ON c.id = t.category_id
      WHERE t.type = ? AND t.date >= ? AND t.date < ?
      GROUP BY c.id
      ORDER BY total DESC
    ''',
      [type.value, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return rows.map(CategorySummary.fromMap).toList();
  }
}
