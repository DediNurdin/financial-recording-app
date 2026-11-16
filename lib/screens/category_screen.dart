import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/category_model.dart';
import '../data/models/tx_type.dart';
import '../providers/category_provider.dart';
import '../utils/dialogs.dart';
import '../widgets/category_avatar.dart';
import '../widgets/category_form_dialog.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  static const _tabs = [TxType.expense, TxType.income];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kategori'),
          bottom: TabBar(tabs: [for (final t in _tabs) Tab(text: t.label)]),
        ),
        body: TabBarView(
          children: [for (final t in _tabs) _CategoryList(type: t)],
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton(
            heroTag: 'fab-category',
            tooltip: 'Tambah kategori',
            onPressed: () => showCategoryFormDialog(
              ctx,
              type: _tabs[DefaultTabController.of(ctx).index],
            ),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.type});

  final TxType type;

  Future<void> _delete(BuildContext context, CategoryModel c) async {
    final provider = context.read<CategoryProvider>();
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus kategori?',
      message: 'Kategori "${c.name}" akan dihapus.',
    );
    if (!ok) return;
    final deleted = await provider.delete(c.id!);
    if (!deleted && context.mounted) {
      showSnack(
        context,
        'Kategori masih dipakai oleh transaksi sehingga tidak bisa dihapus',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<CategoryProvider>().byType(type);
    if (items.isEmpty) {
      return const Center(child: Text('Belum ada kategori'));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final c = items[i];
        return ListTile(
          leading: CategoryAvatar(icon: c.icon, color: c.color),
          title: Text(c.name),
          onTap: () => showCategoryFormDialog(context, type: type, initial: c),
          trailing: IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, c),
          ),
        );
      },
    );
  }
}
