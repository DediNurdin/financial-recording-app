import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/category_style.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/wallet_style.dart';
import '../widgets/amount_field.dart';

/// returns the saved wallet id, or null
Future<int?> openWalletForm(BuildContext context, {WalletModel? wallet}) =>
    Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => WalletFormScreen(initial: wallet)),
    );

class WalletFormScreen extends StatefulWidget {
  const WalletFormScreen({super.key, this.initial});

  final WalletModel? initial;

  @override
  State<WalletFormScreen> createState() => _WalletFormScreenState();
}

class _WalletFormScreenState extends State<WalletFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.initial?.name);
  late final _balanceCtrl = TextEditingController(
    text: widget.initial == null
        ? ''
        : formatNumber(widget.initial!.initialBalance),
  );
  late WalletType _type = widget.initial?.type ?? WalletType.cash;
  late int _color = widget.initial?.color ?? kCategoryColors[9];
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final wallets = context.read<WalletProvider>();
    final transactions = context.read<TransactionProvider>();
    final nav = Navigator.of(context);
    final id = await wallets.save(
      WalletModel(
        id: widget.initial?.id,
        name: _nameCtrl.text.trim(),
        type: _type,
        color: _color,
        initialBalance: parseAmount(_balanceCtrl.text),
      ),
    );
    // wallet names are shown on transaction tiles
    if (_isEdit) await transactions.refresh();
    nav.pop(id);
  }

  Future<void> _delete() async {
    final provider = context.read<WalletProvider>();
    final nav = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus dompet?',
      message: 'Dompet "${widget.initial!.name}" akan dihapus.',
    );
    if (!ok) return;
    final error = await provider.delete(widget.initial!.id!);
    if (!mounted) return;
    if (error != null) {
      showSnack(context, error);
      return;
    }
    // close form and detail screen
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final preview = WalletModel(name: '', type: _type, color: _color);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Dompet' : 'Dompet Baru'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Hapus',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: WalletAvatar(wallet: preview, radius: 32)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama dompet',
                hintText: 'mis. BCA, GoPay, Piutang Budi',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            Text('Jenis', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in WalletType.values)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(walletIcon(t), size: 18),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AmountField(
              controller: _balanceCtrl,
              label: 'Saldo awal',
              allowZero: true,
              helperText: _type == WalletType.receivable
                  ? 'Jumlah piutang yang belum dibayar'
                  : 'Saldo saat dompet mulai dicatat',
            ),
            const SizedBox(height: 20),
            Text('Warna', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kCategoryColors)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(c),
                      child: _color == c
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Simpan'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
