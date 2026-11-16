import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/transaction_model.dart';
import '../data/models/tx_type.dart';
import '../data/models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/wallet_style.dart';
import '../theme.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../widgets/period_pickers.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';
import 'wallet_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TransactionProvider>();
    final wallets = context.watch<WalletProvider>();
    final rows = _buildRows(p.items);

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Keuangan')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-transaction',
        onPressed: () => openTransactionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  PeriodNavigator(
                    label: formatMonthYear(p.month),
                    onPrev: () => p.shiftMonth(-1),
                    onNext: () => p.shiftMonth(1),
                    onTap: () async {
                      final m = await showMonthPicker(
                        context,
                        initial: p.month,
                      );
                      if (m != null) p.setMonth(m);
                    },
                  ),
                  _SummaryCard(
                    balance: wallets.total,
                    income: p.monthIncome,
                    expense: p.monthExpense,
                  ),
                  const SizedBox(height: 12),
                  _WalletStrip(wallets: wallets.items),
                  const SizedBox(height: 12),
                  _FilterBar(value: p.filter, onChanged: p.setFilter),
                ],
              ),
            ),
          ),
          if (p.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rows.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 96),
              sliver: SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => switch (rows[i]) {
                  _DayRow r => _DayHeader(row: r),
                  _TxRow r => _DismissibleTile(tx: r.tx),
                },
              ),
            ),
        ],
      ),
    );
  }

  static List<_Row> _buildRows(List<TransactionModel> items) {
    final rows = <_Row>[];
    _DayRow? current;
    for (final tx in items) {
      if (current == null || !_sameDay(current.date, tx.date)) {
        current = _DayRow(tx.date);
        rows.add(current);
      }
      current.net += tx.isIncome ? tx.amount : -tx.amount;
      rows.add(_TxRow(tx));
    }
    return rows;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

Future<void> openTransactionForm(
  BuildContext context, {
  TransactionModel? tx,
  int? walletId,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => TransactionFormScreen(initial: tx, walletId: walletId),
  ),
);

class _WalletStrip extends StatelessWidget {
  const _WalletStrip({required this.wallets});

  final List<WalletModel> wallets;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final w = wallets[i];
          return Card.outlined(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WalletDetailScreen(walletId: w.id!),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    WalletAvatar(wallet: w, radius: 16),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.name, style: text.bodySmall),
                        Text(
                          formatCurrency(w.balance),
                          style: text.labelLarge?.copyWith(
                            color: w.balance < 0 ? kExpenseColor : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

sealed class _Row {}

class _DayRow extends _Row {
  _DayRow(this.date);
  final DateTime date;
  int net = 0;
}

class _TxRow extends _Row {
  _TxRow(this.tx);
  final TransactionModel tx;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  final int balance;
  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Saldo',
              style: text.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                formatCurrency(balance),
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Pemasukan',
                    value: income,
                    color: kIncomeColor,
                    icon: Icons.south_west,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Pengeluaran',
                    value: expense,
                    color: kExpenseColor,
                    icon: Icons.north_east,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatCurrency(value),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final TxType? value;
  final ValueChanged<TxType?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TxType? type) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: value == type,
        onSelected: (_) => onChanged(type),
      ),
    );
    return Row(
      children: [
        chip('Semua', null),
        chip(TxType.income.label, TxType.income),
        chip(TxType.expense.label, TxType.expense),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.row});

  final _DayRow row;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(formatDayHeader(row.date), style: style)),
          Text(
            '${row.net >= 0 ? '+' : '-'} ${formatCurrency(row.net.abs())}',
            style: style?.copyWith(
              color: row.net >= 0 ? kIncomeColor : kExpenseColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissibleTile extends StatelessWidget {
  const _DismissibleTile({required this.tx});

  final TransactionModel tx;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) => showConfirmDialog(
        context,
        title: 'Hapus transaksi?',
        message: 'Transaksi ${formatCurrency(tx.amount)} akan dihapus.',
      ),
      onDismissed: (_) {
        final provider = context.read<TransactionProvider>();
        provider.delete(tx);
        showSnack(
          context,
          'Transaksi dihapus',
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => provider.restore(tx),
          ),
        );
      },
      child: TransactionTile(
        tx: tx,
        onTap: () => openTransactionForm(context, tx: tx),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: color),
          const SizedBox(height: 12),
          Text(
            'Belum ada transaksi di bulan ini',
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
