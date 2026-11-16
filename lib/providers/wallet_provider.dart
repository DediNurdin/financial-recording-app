import 'package:flutter/foundation.dart';

import '../data/models/transfer_model.dart';
import '../data/models/wallet_model.dart';
import '../data/repositories/wallet_repository.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider({WalletRepository? repository})
    : _repo = repository ?? WalletRepository();

  final WalletRepository _repo;
  List<WalletModel> _items = [];
  int _requestId = 0;

  List<WalletModel> get items => List.unmodifiable(_items);
  int get total => _items.fold(0, (sum, w) => sum + w.balance);

  WalletModel? byId(int? id) {
    for (final w in _items) {
      if (w.id == id) return w;
    }
    return null;
  }

  Future<void> load() async {
    final req = ++_requestId;
    final items = await _repo.getAllWithBalance();
    if (req != _requestId) return;
    _items = items;
    notifyListeners();
  }

  /// returns id of the saved wallet
  Future<int> save(WalletModel wallet) async {
    final id = wallet.id ?? await _repo.insert(wallet);
    if (wallet.id != null) await _repo.update(wallet);
    await load();
    return id;
  }

  /// null on success, otherwise the reason it cannot be deleted
  Future<String?> delete(int id) async {
    if (_items.length <= 1) return 'Minimal harus ada satu dompet';
    if (await _repo.isUsed(id)) {
      return 'Dompet masih dipakai oleh transaksi/transfer sehingga tidak bisa dihapus';
    }
    await _repo.delete(id);
    await load();
    return null;
  }

  Future<void> saveTransfer(TransferModel transfer) async {
    if (transfer.id == null) {
      await _repo.insertTransfer(transfer);
    } else {
      await _repo.updateTransfer(transfer);
    }
    await load();
  }

  Future<void> deleteTransfer(int id) async {
    await _repo.deleteTransfer(id);
    await load();
  }
}
