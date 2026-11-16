import 'package:flutter/material.dart';

import '../data/models/wallet_model.dart';
import '../utils/formatters.dart';
import '../utils/wallet_style.dart';

class WalletDropdown extends StatelessWidget {
  const WalletDropdown({
    super.key,
    required this.wallets,
    required this.value,
    required this.onChanged,
    required this.label,
    this.validator,
  });

  final List<WalletModel> wallets;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;
  final FormFieldValidator<int>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      // rebuild when the selection is changed from outside
      key: ValueKey('$label-$value-${wallets.length}'),
      initialValue: wallets.any((w) => w.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      validator: validator ?? (v) => v == null ? 'Pilih dompet' : null,
      items: [
        for (final w in wallets)
          DropdownMenuItem(
            value: w.id,
            child: Row(
              children: [
                WalletAvatar(wallet: w, radius: 14),
                const SizedBox(width: 12),
                Expanded(child: Text(w.name, overflow: TextOverflow.ellipsis)),
                Text(
                  formatCurrency(w.balance),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
