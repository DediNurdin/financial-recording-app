import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/transaction_model.dart';
import '../data/models/transfer_model.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../providers/wallet_provider.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/wallet_style.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transfer_tile.dart';
import 'home_screen.dart';
import 'transfer_form_screen.dart';
import 'wallet_form_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({super.key, required this.walletId});

  final int walletId;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  final _txRepo = TransactionRepository();
  final _walletRepo = WalletRepository();
  late final WalletProvider _wallets;

  /// TransactionModel or TransferModel, newest first
  List<Object> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // wallet provider also reloads after every transaction change
    _wallets = context.read<WalletProvider>()..addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _wallets.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final txs = await _txRepo.getByWallet(widget.walletId);
    final transfers = await _walletRepo.transfersByWallet(widget.walletId);
    if (!mounted) return;
    final entries = <Object>[...txs, ...transfers]
      ..sort((a, b) {
        final byDate = _date(b).compareTo(_date(a));
        return byDate != 0 ? byDate : _id(b).compareTo(_id(a));
      });
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  static DateTime _date(Object e) =>
      e is TransactionModel ? e.date : (e as TransferModel).date;
  static int _id(Object e) =>
      (e is TransactionModel ? e.id : (e as TransferModel).id) ?? 0;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>().byId(widget.walletId);
    // wallet was deleted
    if (wallet == null) return const Scaffold();

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(wallet.name),
        actions: [
          IconButton(
            tooltip: 'Edit dompet',
            onPressed: () => openWalletForm(context, wallet: wallet),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        WalletAvatar(wallet: wallet),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            wallet.type.label,
                            style: text.titleSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Saldo saat ini',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    FittedBox(
                      child: Text(
                        formatCurrency(wallet.balance),
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: wallet.balance < 0
                              ? kExpenseColor
                              : scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      'Saldo awal ${formatCurrency(wallet.initialBalance)}',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openTransactionForm(
                              context,
                              walletId: wallet.id,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Catat'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _wallets.items.length < 2
                                ? null
                                : () => openTransferForm(
                                    context,
                                    fromWalletId: wallet.id,
                                  ),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Transfer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('Riwayat Mutasi', style: text.titleSmall),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Belum ada mutasi',
                  style: TextStyle(color: scheme.outline),
                ),
              ),
            )
          else
            for (final e in _entries)
              switch (e) {
                TransactionModel tx => TransactionTile(
                  tx: tx,
                  showDate: true,
                  onTap: () => openTransactionForm(context, tx: tx),
                ),
                TransferModel t => TransferTile(
                  transfer: t,
                  walletId: wallet.id!,
                  onTap: () => openTransferForm(context, transfer: t),
                ),
                _ => const SizedBox.shrink(),
              },
        ],
      ),
    );
  }
}
