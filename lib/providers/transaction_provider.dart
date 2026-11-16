import 'package:flutter/foundation.dart';

import '../data/models/transaction_model.dart';
import '../data/models/tx_type.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({TransactionRepository? repository})
    : _repo = repository ?? TransactionRepository();

  final TransactionRepository _repo;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<TransactionModel> _items = [];
  TxType? _filter;
  int _monthIncome = 0;
  int _monthExpense = 0;
  bool _loading = true;
  int _requestId = 0;

  DateTime get month => _month;
  TxType? get filter => _filter;
  int get monthIncome => _monthIncome;
  int get monthExpense => _monthExpense;
  bool get loading => _loading;

  List<TransactionModel> get items => _filter == null
      ? List.unmodifiable(_items)
      : _items.where((t) => t.type == _filter).toList();

  Future<void> refresh() async {
    final req = ++_requestId;
    final start = _month;
    final end = DateTime(_month.year, _month.month + 1);
    final items = await _repo.getByRange(start, end);
    final monthTotals = await _repo.totals(start: start, end: end);
    if (req != _requestId) return;
    _items = items;
    _monthIncome = monthTotals.income;
    _monthExpense = monthTotals.expense;
    _loading = false;
    notifyListeners();
  }

  void setMonth(DateTime month) {
    _month = DateTime(month.year, month.month);
    notifyListeners();
    refresh();
  }

  void shiftMonth(int delta) =>
      setMonth(DateTime(_month.year, _month.month + delta));

  void setFilter(TxType? filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> save(TransactionModel tx) async {
    if (tx.id == null) {
      await _repo.insert(tx);
    } else {
      await _repo.update(tx);
    }
    await refresh();
  }

  Future<void> delete(TransactionModel tx) async {
    // remove synchronously so a Dismissible leaves the tree immediately
    _items = _items.where((t) => t.id != tx.id).toList();
    notifyListeners();
    await _repo.delete(tx.id!);
    await refresh();
  }

  /// re-insert a deleted transaction (undo)
  Future<void> restore(TransactionModel tx) async {
    await _repo.insert(tx);
    await refresh();
  }
}
