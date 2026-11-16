import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/transaction_model.dart';
import '../data/models/tx_type.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme.dart';
import '../utils/category_style.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../widgets/amount_field.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/wallet_dropdown.dart';
import 'wallet_form_screen.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.initial, this.walletId});

  final TransactionModel? initial;

  /// preselected wallet for new transactions
  final int? walletId;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TxType _type = widget.initial?.type ?? TxType.expense;
  late int? _categoryId = widget.initial?.categoryId;
  late int? _walletId = widget.initial?.walletId ?? widget.walletId;
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

  Future<void> _addCategory() async {
    final id = await showCategoryFormDialog(context, type: _type);
    if (id != null) setState(() => _categoryId = id);
  }

  Future<void> _addWallet() async {
    final id = await openWalletForm(context);
    if (id != null) setState(() => _walletId = id);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      showSnack(context, 'Pilih kategori terlebih dahulu');
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<TransactionProvider>();
    final nav = Navigator.of(context);
    await provider.save(
      TransactionModel(
        id: widget.initial?.id,
        type: _type,
        amount: parseAmount(_amountCtrl.text),
        categoryId: _categoryId!,
        walletId: _walletId!,
        date: _date,
        note: _noteCtrl.text.trim(),
      ),
    );
    nav.pop();
  }

  Future<void> _delete() async {
    final provider = context.read<TransactionProvider>();
    final nav = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus transaksi?',
      message: 'Transaksi ini akan dihapus permanen.',
    );
    if (!ok) return;
    await provider.delete(widget.initial!);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().byType(_type);
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.items;
    _walletId ??= wallets.isEmpty ? null : wallets.first.id;
    final typeColor = _type == TxType.income ? kIncomeColor : kExpenseColor;
    final isExpense = _type == TxType.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
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
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(
                  value: TxType.expense,
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.north_east),
                ),
                ButtonSegment(
                  value: TxType.income,
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.south_west),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 20),
            AmountField(
              controller: _amountCtrl,
              color: typeColor,
              autofocus: !_isEdit,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: WalletDropdown(
                    label: isExpense ? 'Bayar dari dompet' : 'Masuk ke dompet',
                    wallets: wallets,
                    value: _walletId,
                    onChanged: (v) => setState(() => _walletId = v),
                  ),
                ),
                IconButton(
                  tooltip: 'Dompet baru',
                  onPressed: _addWallet,
                  icon: const Icon(Icons.add_card),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Kategori', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(
                      iconFor(c.icon),
                      size: 18,
                      color: Color(c.color),
                    ),
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Baru'),
                  onPressed: _addCategory,
                ),
              ],
            ),
            const SizedBox(height: 20),
            DateField(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
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
