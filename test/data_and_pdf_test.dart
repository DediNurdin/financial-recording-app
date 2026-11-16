import 'dart:io';

import 'package:financial_recording/data/app_database.dart';
import 'package:financial_recording/data/models/category_model.dart';
import 'package:financial_recording/data/models/report_data.dart';
import 'package:financial_recording/data/models/transaction_model.dart';
import 'package:financial_recording/data/models/transfer_model.dart';
import 'package:financial_recording/data/models/tx_type.dart';
import 'package:financial_recording/data/models/wallet_model.dart';
import 'package:financial_recording/data/repositories/category_repository.dart';
import 'package:financial_recording/data/repositories/transaction_repository.dart';
import 'package:financial_recording/data/repositories/wallet_repository.dart';
import 'package:financial_recording/services/pdf_report_service.dart';
import 'package:financial_recording/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final categories = CategoryRepository();
  final transactions = TransactionRepository();
  final wallets = WalletRepository();

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    AppDatabase.pathOverride = inMemoryDatabasePath;
  });

  Future<(CategoryModel, CategoryModel, WalletModel, WalletModel)>
  fixtures() async {
    final all = await categories.getAll();
    final ws = await wallets.getAllWithBalance();
    return (
      all.firstWhere((c) => c.type == TxType.income),
      all.firstWhere((c) => c.type == TxType.expense),
      ws[0],
      ws[1],
    );
  }

  test('seeds default categories and wallets', () async {
    final all = await categories.getAll();
    expect(all.where((c) => c.type == TxType.income), isNotEmpty);
    expect(all.where((c) => c.type == TxType.expense), isNotEmpty);
    expect((await wallets.getAllWithBalance()).length, 2);
  });

  test('totals, range query and category summary', () async {
    final (inc, exp, cash, _) = await fixtures();
    await transactions.insert(
      TransactionModel(
        type: TxType.income,
        amount: 5000000,
        categoryId: inc.id!,
        walletId: cash.id!,
        date: DateTime(2026, 11, 1),
      ),
    );
    await transactions.insert(
      TransactionModel(
        type: TxType.expense,
        amount: 150000,
        categoryId: exp.id!,
        walletId: cash.id!,
        date: DateTime(2026, 11, 3),
        note: 'makan',
      ),
    );
    await transactions.insert(
      TransactionModel(
        type: TxType.expense,
        amount: 50000,
        categoryId: exp.id!,
        walletId: cash.id!,
        date: DateTime(2026, 12, 1),
      ),
    );

    final nov = await transactions.totals(
      start: DateTime(2026, 11),
      end: DateTime(2026, 12),
    );
    expect(nov, (income: 5000000, expense: 150000));
    expect(await transactions.totals(), (income: 5000000, expense: 200000));

    final list = await transactions.getByRange(
      DateTime(2026, 11),
      DateTime(2026, 12),
    );
    expect(list.length, 2);
    expect(list.first.categoryName, exp.name);
    expect(list.first.walletName, cash.name);
    expect(list.first.note, 'makan');

    final summary = await transactions.categorySummary(
      DateTime(2026, 1),
      DateTime(2027, 1),
      TxType.expense,
    );
    expect(summary.single.total, 200000);
    expect(summary.single.count, 2);
    expect(await categories.isUsed(exp.id!), isTrue);
  });

  test('wallet balance includes initial, transactions and transfers', () async {
    final (inc, exp, cash, bank) = await fixtures();
    await wallets.update(
      WalletModel(
        id: bank.id,
        name: bank.name,
        type: bank.type,
        color: bank.color,
        initialBalance: 1000000,
      ),
    );
    await transactions.insert(
      TransactionModel(
        type: TxType.income,
        amount: 500000,
        categoryId: inc.id!,
        walletId: bank.id!,
        date: DateTime(2026, 11, 1),
      ),
    );
    await wallets.insertTransfer(
      TransferModel(
        fromWalletId: bank.id!,
        toWalletId: cash.id!,
        amount: 300000,
        date: DateTime(2026, 11, 5),
      ),
    );
    await transactions.insert(
      TransactionModel(
        type: TxType.expense,
        amount: 100000,
        categoryId: exp.id!,
        walletId: cash.id!,
        date: DateTime(2026, 11, 6),
      ),
    );

    final now = {
      for (final w in await wallets.getAllWithBalance()) w.id: w.balance,
    };
    expect(now[bank.id], 1000000 + 500000 - 300000);
    expect(now[cash.id], 300000 - 100000);

    // balance as of before the transfer
    final past = {
      for (final w in await wallets.getAllWithBalance(
        until: DateTime(2026, 11, 5),
      ))
        w.id: w.balance,
    };
    expect(past[bank.id], 1500000);
    expect(past[cash.id], 0);

    final cashTransfers = await wallets.transfersByWallet(cash.id!);
    expect(cashTransfers.single.fromName, bank.name);
    expect(await wallets.isUsed(cash.id!), isTrue);
  });

  test('migrates v1 database and assigns existing data to cash wallet', () async {
    final dir = await Directory.systemTemp.createTemp('fin_db');
    final path = '${dir.path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            "CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, icon TEXT NOT NULL, color INTEGER NOT NULL)",
          );
          await db.execute(
            "CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, amount INTEGER NOT NULL, category_id INTEGER NOT NULL REFERENCES categories(id), date INTEGER NOT NULL, note TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL DEFAULT 0)",
          );
          await db.insert('categories', {
            'name': 'Makan',
            'type': 'expense',
            'icon': 'food',
            'color': 0xFFFB8C00,
          });
          await db.insert('transactions', {
            'type': 'expense',
            'amount': 25000,
            'category_id': 1,
            'date': DateTime(2026, 10, 1).millisecondsSinceEpoch,
          });
        },
      ),
    );
    await v1.close();

    AppDatabase.pathOverride = path;
    final txs = await transactions.getByRange(
      DateTime(2026, 10),
      DateTime(2026, 11),
    );
    expect(txs.single.walletName, 'Tunai');
    final ws = await wallets.getAllWithBalance();
    expect(ws.firstWhere((w) => w.name == 'Tunai').balance, -25000);

    await AppDatabase.instance.close();
    await dir.delete(recursive: true);
  });

  test('pdf report builds', () async {
    final (inc, exp, cash, _) = await fixtures();
    final txs = [
      TransactionModel(
        id: 2,
        type: TxType.expense,
        amount: 150000,
        categoryId: exp.id!,
        walletId: cash.id!,
        date: DateTime(2026, 11, 3),
        note: 'Kopi ☕ & roti',
        categoryName: exp.name,
        walletName: cash.name,
      ),
      TransactionModel(
        id: 1,
        type: TxType.income,
        amount: 5000000,
        categoryId: inc.id!,
        walletId: cash.id!,
        date: DateTime(2026, 11, 1),
        categoryName: inc.name,
        walletName: cash.name,
      ),
    ];
    final bytes = await PdfReportService.build(
      ReportData(
        periodLabel: 'November 2026',
        start: DateTime(2026, 11),
        end: DateTime(2026, 12),
        income: 5000000,
        expense: 150000,
        incomeByCategory: [],
        expenseByCategory: [],
        transactions: txs,
        wallets: await wallets.getAllWithBalance(),
      ),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('thousands formatter', () {
    final f = ThousandsInputFormatter();
    final out = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1500000'),
    );
    expect(out.text, '1.500.000');
    expect(parseAmount(out.text), 1500000);
    expect(formatCurrency(25000), 'Rp 25.000');
  });
}
