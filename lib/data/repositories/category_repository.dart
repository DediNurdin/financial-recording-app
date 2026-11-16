import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../models/category_model.dart';

class CategoryRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<CategoryModel>> getAll() async {
    final rows = await (await _db).query('categories', orderBy: 'id');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> insert(CategoryModel c) async =>
      (await _db).insert('categories', c.toMap());

  Future<void> update(CategoryModel c) async => (await _db).update(
    'categories',
    c.toMap(),
    where: 'id = ?',
    whereArgs: [c.id],
  );

  Future<bool> isUsed(int id) async {
    final rows = await (await _db).rawQuery(
      'SELECT 1 FROM transactions WHERE category_id = ? LIMIT 1',
      [id],
    );
    return rows.isNotEmpty;
  }

  Future<void> delete(int id) async =>
      (await _db).delete('categories', where: 'id = ?', whereArgs: [id]);
}
