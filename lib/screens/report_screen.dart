import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/category_summary.dart';
import '../data/models/report_data.dart';
import '../data/models/tx_type.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/models/wallet_model.dart';
import '../data/repositories/wallet_repository.dart';
import '../providers/wallet_provider.dart';
import '../utils/wallet_style.dart';
import '../theme.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../widgets/category_avatar.dart';
import '../widgets/period_pickers.dart';
import 'pdf_preview_screen.dart';

enum ReportPeriod {
  monthly('Bulanan'),
  yearly('Tahunan'),
  custom('Rentang');

  const ReportPeriod(this.label);
  final String label;
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _repo = TransactionRepository();
  final _walletRepo = WalletRepository();

  /// reloads after transaction, transfer and wallet changes
  late final WalletProvider _walletProvider;

  ReportPeriod _period = ReportPeriod.monthly;
  DateTime _anchor = DateTime(DateTime.now().year, DateTime.now().month);
  DateTimeRange _custom = DateTimeRange(
    start: DateUtils.dateOnly(
      DateTime.now(),
    ).subtract(const Duration(days: 29)),
    end: DateUtils.dateOnly(DateTime.now()),
  );
  TxType _chartType = TxType.expense;
  ReportData? _data;
  bool _loading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _walletProvider = context.read<WalletProvider>()..addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _walletProvider.removeListener(_load);
    super.dispose();
  }

  (DateTime, DateTime) get _range => switch (_period) {
    ReportPeriod.monthly => (
      DateTime(_anchor.year, _anchor.month),
      DateTime(_anchor.year, _anchor.month + 1),
    ),
    ReportPeriod.yearly => (DateTime(_anchor.year), DateTime(_anchor.year + 1)),
    ReportPeriod.custom => (
      _custom.start,
      DateTime(_custom.end.year, _custom.end.month, _custom.end.day + 1),
    ),
  };

  String get _label => switch (_period) {
    ReportPeriod.monthly => formatMonthYear(_anchor),
    ReportPeriod.yearly => '${_anchor.year}',
    ReportPeriod.custom =>
      '${formatDate(_custom.start)} - ${formatDate(_custom.end)}',
  };

  Future<void> _load() async {
    final req = ++_requestId;
    if (mounted) setState(() => _loading = true);
    final (start, end) = _range;
    final label = _label;
    final totals = await _repo.totals(start: start, end: end);
    final income = await _repo.categorySummary(start, end, TxType.income);
    final expense = await _repo.categorySummary(start, end, TxType.expense);
    final txs = await _repo.getByRange(start, end);
    final wallets = await _walletRepo.getAllWithBalance(until: end);
    if (!mounted || req != _requestId) return;
    setState(() {
      _loading = false;
      _data = ReportData(
        periodLabel: label,
        start: start,
        end: end,
        income: totals.income,
        expense: totals.expense,
        incomeByCategory: income,
        expenseByCategory: expense,
        transactions: txs,
        wallets: wallets,
      );
    });
  }

  void _shift(int delta) {
    _anchor = _period == ReportPeriod.monthly
        ? DateTime(_anchor.year, _anchor.month + delta)
        : DateTime(_anchor.year + delta);
    _load();
  }

  Future<void> _pickPeriod() async {
    switch (_period) {
      case ReportPeriod.monthly:
        final m = await showMonthPicker(context, initial: _anchor);
        if (m == null) return;
        _anchor = m;
      case ReportPeriod.yearly:
        final y = await showYearPicker(context, initial: _anchor);
        if (y == null) return;
        _anchor = DateTime(y.year, _anchor.month);
      case ReportPeriod.custom:
        final r = await showDateRangePicker(
          context: context,
          initialDateRange: _custom,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (r == null) return;
        _custom = r;
    }
    _load();
  }

  void _exportPdf() {
    final data = _data;
    if (data == null) return;
    if (data.transactions.isEmpty) {
      showSnack(context, 'Tidak ada transaksi pada periode ini');
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PdfPreviewScreen(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final summaries = data == null
        ? const <CategorySummary>[]
        : _chartType == TxType.expense
        ? data.expenseByCategory
        : data.incomeByCategory;
    final chartTotal = data == null
        ? 0
        : _chartType == TxType.expense
        ? data.expense
        : data.income;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: data == null ? null : _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<ReportPeriod>(
            segments: [
              for (final p in ReportPeriod.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {_period},
            onSelectionChanged: (s) {
              _period = s.first;
              _load();
            },
          ),
          const SizedBox(height: 8),
          PeriodNavigator(
            label: _label,
            onTap: _pickPeriod,
            onPrev: _period == ReportPeriod.custom ? null : () => _shift(-1),
            onNext: _period == ReportPeriod.custom ? null : () => _shift(1),
          ),
          SizedBox(
            height: 4,
            child: _loading ? const LinearProgressIndicator() : null,
          ),
          const SizedBox(height: 8),
          if (data != null) ...[
            _TotalsCard(data: data),
            const SizedBox(height: 16),
            _WalletBalancesCard(data: data),
            const SizedBox(height: 16),
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(
                  value: TxType.expense,
                  label: Text('Pengeluaran'),
                ),
                ButtonSegment(value: TxType.income, label: Text('Pemasukan')),
              ],
              selected: {_chartType},
              onSelectionChanged: (s) => setState(() => _chartType = s.first),
            ),
            const SizedBox(height: 16),
            if (summaries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'Tidak ada data ${_chartType.label.toLowerCase()}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              )
            else ...[
              _CategoryPieChart(items: summaries, total: chartTotal),
              const SizedBox(height: 16),
              for (final s in summaries)
                _CategoryBreakdownTile(summary: s, total: chartTotal),
            ],
          ],
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, int value, Color color, {bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                formatCurrency(value),
                style: TextStyle(
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  fontSize: bold ? 16 : null,
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row('Pemasukan', data.income, kIncomeColor),
            row('Pengeluaran', data.expense, kExpenseColor),
            const Divider(),
            row(
              data.net >= 0 ? 'Surplus' : 'Defisit',
              data.net,
              data.net >= 0 ? kIncomeColor : kExpenseColor,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({required this.items, required this.total});

  final List<CategorySummary> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: [
                for (final s in items)
                  PieChartSectionData(
                    value: s.total.toDouble(),
                    color: Color(s.color),
                    radius: 40,
                    title: s.total / total >= 0.06
                        ? '${(s.total / total * 100).round()}%'
                        : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(
                width: 110,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatCurrency(total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownTile extends StatelessWidget {
  const _CategoryBreakdownTile({required this.summary, required this.total});

  final CategorySummary summary;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : summary.total / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CategoryAvatar(icon: summary.icon, color: summary.color, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatCurrency(summary.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    color: Color(summary.color),
                    backgroundColor: Color(
                      summary.color,
                    ).withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(ratio * 100).toStringAsFixed(1)}% · ${summary.count} transaksi',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalancesCard extends StatelessWidget {
  const _WalletBalancesCard({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Saldo Dompet per ${formatDate(data.endInclusive)}',
                style: text.titleSmall,
              ),
            ),
            for (final WalletModel w in data.wallets)
              ListTile(
                dense: true,
                leading: WalletAvatar(wallet: w, radius: 16),
                title: Text(w.name),
                subtitle: Text(w.type.label),
                trailing: Text(
                  formatCurrency(w.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: w.balance < 0 ? kExpenseColor : null,
                  ),
                ),
              ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Total')),
                  Text(
                    formatCurrency(data.walletTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
