import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/category_model.dart';
import '../data/models/tx_type.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/category_style.dart';
import 'category_avatar.dart';

/// returns the saved category id, or null when cancelled
Future<int?> showCategoryFormDialog(
  BuildContext context, {
  required TxType type,
  CategoryModel? initial,
}) => showDialog<int>(
  context: context,
  builder: (_) => _CategoryFormDialog(type: type, initial: initial),
);

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({required this.type, this.initial});

  final TxType type;
  final CategoryModel? initial;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final _nameCtrl = TextEditingController(text: widget.initial?.name);
  late String _icon = widget.initial?.icon ?? 'other';
  late int _color = widget.initial?.color ?? kCategoryColors[5];
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama kategori wajib diisi');
      return;
    }
    setState(() => _saving = true);
    final categories = context.read<CategoryProvider>();
    final transactions = context.read<TransactionProvider>();
    final nav = Navigator.of(context);
    final category =
        widget.initial?.copyWith(name: name, icon: _icon, color: _color) ??
        CategoryModel(
          name: name,
          type: widget.type,
          icon: _icon,
          color: _color,
        );
    final id = await categories.save(category);
    if (widget.initial != null) await transactions.refresh();
    nav.pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.titleSmall;

    return AlertDialog(
      title: Text(
        widget.initial == null
            ? 'Kategori ${widget.type.label} Baru'
            : 'Edit Kategori',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CategoryAvatar(icon: _icon, color: _color, radius: 28),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                autofocus: widget.initial == null,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama kategori',
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              Text('Ikon', style: labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in kCategoryIcons.entries)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _icon = e.key),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _icon == e.key
                            ? Color(_color)
                            : scheme.surfaceContainerHighest,
                        child: Icon(
                          e.value,
                          size: 20,
                          color: _icon == e.key
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Warna', style: labelStyle),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
