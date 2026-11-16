import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/wallet_model.dart';
import '../providers/wallet_provider.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/wallet_style.dart';
import 'transfer_form_screen.dart';
import 'wallet_detail_screen.dart';
import 'wallet_form_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final wallets = provider.items;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet'),
        actions: [
          IconButton(
            tooltip: 'Transfer antar dompet',
            onPressed: wallets.length < 2
                ? null
                : () => openTransferForm(context),
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-wallet',
        onPressed: () => openWalletForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Dompet'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Saldo Semua Dompet',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(
                      formatCurrency(provider.total),
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${wallets.length} dompet',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final type in WalletType.values)
            ..._section(
              context,
              type,
              wallets.where((w) => w.type == type).toList(),
            ),
        ],
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    WalletType type,
    List<WalletModel> items,
  ) {
    if (items.isEmpty) return const [];
    final subtotal = items.fold<int>(0, (s, w) => s + w.balance);
    final style = Theme.of(context).textTheme.labelLarge;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Row(
          children: [
            Expanded(child: Text(type.label, style: style)),
            Text(formatCurrency(subtotal), style: style),
          ],
        ),
      ),
      Card(
        child: Column(
          children: [
            for (final w in items)
              ListTile(
                leading: WalletAvatar(wallet: w),
                title: Text(w.name),
                subtitle: Text(type.label),
                trailing: Text(
                  formatCurrency(w.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: w.balance < 0 ? kExpenseColor : null,
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WalletDetailScreen(walletId: w.id!),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ];
  }
}
