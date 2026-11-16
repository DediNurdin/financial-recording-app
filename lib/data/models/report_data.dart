import 'category_summary.dart';
import 'transaction_model.dart';
import 'wallet_model.dart';

class ReportData {
  const ReportData({
    required this.periodLabel,
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.transactions,
    required this.wallets,
  });

  final String periodLabel;
  final DateTime start;

  /// exclusive
  final DateTime end;
  final int income;
  final int expense;
  final List<CategorySummary> incomeByCategory;
  final List<CategorySummary> expenseByCategory;

  /// sorted newest first
  final List<TransactionModel> transactions;

  /// wallet balances as of [end]
  final List<WalletModel> wallets;

  int get walletTotal => wallets.fold(0, (s, w) => s + w.balance);

  int get net => income - expense;
  DateTime get endInclusive => DateTime(end.year, end.month, end.day - 1);
}
