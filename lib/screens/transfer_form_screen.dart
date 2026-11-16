import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/transfer_model.dart';
import '../providers/wallet_provider.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../widgets/amount_field.dart';
import '../widgets/wallet_dropdown.dart';

Future<void> openTransferForm(
  BuildContext context, {
  TransferModel? transfer,
  int? fromWalletId,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) =>
        TransferFormScreen(initial: transfer, fromWalletId: fromWalletId),
  ),
);

class TransferFormScreen extends StatefulWidget {
  const TransferFormScreen({super.key, this.initial, this.fromWalletId});

  final TransferModel? initial;
  final int? fromWalletId;

  @override
  State<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends State<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late int? _fromId = widget.initial?.fromWalletId ?? widget.fromWalletId;
  late int? _toId = widget.initial?.toWalletId;
  late DateTime _date =
      widget.initial?.date ?? DateUtils.dateOnly(DateTime.now());
  late final _amountCtrl = TextEditingController(
    text: widget.initial == null ? '' : formatNumber(widget.initial!.amount),
  );
  late final _noteCtrl = TextEditingController(text: widget.initial?.note);
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<WalletProvider>();
    final nav = Navigator.of(context);
    await provider.saveTransfer(
      TransferModel(
        id: widget.initial?.id,
        fromWalletId: _fromId!,
        toWalletId: _toId!,
        amount: parseAmount(_amountCtrl.text),
        date: _date,
        note: _noteCtrl.text.trim(),
      ),
    );
    nav.pop();
  }

  Future<void> _delete() async {
    final provider = context.read<WalletProvider>();
    final nav = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus transfer?',
      message: 'Saldo kedua dompet akan dikembalikan.',
    );
    if (!ok) return;
    await provider.deleteTransfer(widget.initial!.id!);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<WalletProvider>().items;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transfer' : 'Transfer Antar Dompet'),
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
            WalletDropdown(
              label: 'Dari dompet',
              wallets: wallets,
              value: _fromId,
              onChanged: (v) => setState(() => _fromId = v),
            ),
            Center(
              child: IconButton(
                tooltip: 'Tukar',
                onPressed: () => setState(() {
                  final tmp = _fromId;
                  _fromId = _toId;
                  _toId = tmp;
                }),
                icon: const Icon(Icons.swap_vert),
              ),
            ),
            WalletDropdown(
              label: 'Ke dompet',
              wallets: wallets,
              value: _toId,
              onChanged: (v) => setState(() => _toId = v),
              validator: (v) {
                if (v == null) return 'Pilih dompet';
                if (v == _fromId) return 'Dompet tujuan harus berbeda';
                return null;
              },
            ),
            const SizedBox(height: 20),
            AmountField(controller: _amountCtrl, autofocus: !_isEdit),
            const SizedBox(height: 20),
            DateField(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _noteCtrl,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
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
