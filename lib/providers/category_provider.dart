import 'package:flutter/foundation.dart';

import '../data/models/category_model.dart';
import '../data/models/tx_type.dart';
import '../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider({CategoryRepository? repository})
    : _repo = repository ?? CategoryRepository();

  final CategoryRepository _repo;
  List<CategoryModel> _items = [];

  List<CategoryModel> get items => List.unmodifiable(_items);

  List<CategoryModel> byType(TxType type) =>
      _items.where((c) => c.type == type).toList();

  Future<void> load() async {
    _items = await _repo.getAll();
    notifyListeners();
  }

  /// returns id of the saved category
  Future<int> save(CategoryModel category) async {
    final id = category.id ?? await _repo.insert(category);
    if (category.id != null) await _repo.update(category);
    await load();
    return id;
  }

  /// false when the category is still used by transactions
  Future<bool> delete(int id) async {
    if (await _repo.isUsed(id)) return false;
    await _repo.delete(id);
    await load();
    return true;
  }
}
