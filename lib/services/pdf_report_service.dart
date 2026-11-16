import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/category_summary.dart';
import '../data/models/report_data.dart';
import '../data/models/transaction_model.dart';
import '../data/models/wallet_model.dart';
import '../utils/formatters.dart';

class PdfReportService {
  static final _primary = PdfColor.fromInt(0xFF00897B);
  static final _income = PdfColor.fromInt(0xFF2E7D32);
  static final _expense = PdfColor.fromInt(0xFFC62828);
  static const _grey = PdfColors.grey600;

  static String fileName(ReportData data) {
    final f = DateFormat('yyyyMMdd');
    return 'laporan_keuangan_${f.format(data.start)}_${f.format(data.endInclusive)}.pdf';
  }

  static Future<Uint8List> build(
    ReportData data, {
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final doc = pw.Document(
      title: 'Laporan Keuangan ${data.periodLabel}',
      author: 'Catatan Keuangan',
      creator: 'Catatan Keuangan',
    );
    final printedAt = DateFormat(
      'd MMMM yyyy HH:mm',
      'id_ID',
    ).format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  'Laporan Keuangan - ${data.periodLabel}',
                  style: const pw.TextStyle(fontSize: 9, color: _grey),
                ),
              ),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dicetak: $printedAt',
                style: const pw.TextStyle(fontSize: 8, color: _grey),
              ),
              pw.Text(
                'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: _grey),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          _title(data),
          pw.SizedBox(height: 16),
          _summary(data),
          pw.SizedBox(height: 24),
          _sectionTitle(
            'Posisi Saldo Dompet per ${formatDate(data.endInclusive)}',
          ),
          _walletTable(data.wallets, data.walletTotal),
          pw.SizedBox(height: 20),
          _sectionTitle('Pengeluaran per Kategori'),
          _categoryTable(data.expenseByCategory, data.expense),
          pw.SizedBox(height: 20),
          _sectionTitle('Pemasukan per Kategori'),
          _categoryTable(data.incomeByCategory, data.income),
          pw.SizedBox(height: 20),
          _sectionTitle('Rincian Transaksi (${data.transactions.length})'),
          ..._transactionTable(data),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _title(ReportData data) {
    final range =
        '${formatDate(data.start)} - ${formatDate(data.endInclusive)}';
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN KEUANGAN',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Periode: ${data.periodLabel}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          pw.Text(range, style: const pw.TextStyle(fontSize: 10, color: _grey)),
        ],
      ),
    );
  }

  static pw.Widget _summary(ReportData data) {
    pw.Widget box(String label, int value, PdfColor color) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: _grey),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              formatCurrency(value),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
    return pw.Row(
      children: [
        box('Total Pemasukan', data.income, _income),
        box('Total Pengeluaran', data.expense, _expense),
        box(
          data.net >= 0 ? 'Surplus' : 'Defisit',
          data.net,
          data.net >= 0 ? _income : _expense,
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _categoryTable(List<CategorySummary> items, int total) {
    if (items.isEmpty) {
      return pw.Text(
        'Tidak ada data',
        style: const pw.TextStyle(fontSize: 10, color: _grey),
      );
    }
    return _table(
      headers: ['Kategori', 'Jumlah Transaksi', 'Persentase', 'Total'],
      data: [
        for (final c in items)
          [
            _latin1(c.name),
            '${c.count}',
            '${(total == 0 ? 0 : c.total / total * 100).toStringAsFixed(1)}%',
            formatCurrency(c.total),
          ],
        [
          'Total',
          '${items.fold<int>(0, (s, c) => s + c.count)}',
          '100%',
          formatCurrency(total),
        ],
      ],
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(2),
      },
      cellAlignments: const {
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static List<pw.Widget> _transactionTable(ReportData data) {
    if (data.transactions.isEmpty) {
      return [
        pw.Text(
          'Tidak ada transaksi pada periode ini',
          style: const pw.TextStyle(fontSize: 10, color: _grey),
        ),
      ];
    }
    final txs = data.transactions.reversed.toList();
    final dateFmt = DateFormat('dd/MM/yyyy');
    String amount(TransactionModel t, bool income) =>
        t.isIncome == income ? formatCurrency(t.amount) : '';

    return [
      _table(
        headers: [
          'No',
          'Tanggal',
          'Kategori',
          'Dompet',
          'Catatan',
          'Pemasukan',
          'Pengeluaran',
        ],
        data: [
          for (var i = 0; i < txs.length; i++)
            [
              '${i + 1}',
              dateFmt.format(txs[i].date),
              _latin1(txs[i].categoryName ?? '-'),
              _latin1(txs[i].walletName ?? '-'),
              _latin1(txs[i].note),
              amount(txs[i], true),
              amount(txs[i], false),
            ],
          [
            '',
            '',
            '',
            '',
            'Total',
            formatCurrency(data.income),
            formatCurrency(data.expense),
          ],
        ],
        columnWidths: const {
          0: pw.FixedColumnWidth(22),
          1: pw.FixedColumnWidth(56),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(1.6),
          4: pw.FlexColumnWidth(2.4),
          5: pw.FlexColumnWidth(2),
          6: pw.FlexColumnWidth(2),
        },
        cellAlignments: const {
          0: pw.Alignment.center,
          5: pw.Alignment.centerRight,
          6: pw.Alignment.centerRight,
        },
      ),
    ];
  }

  static pw.Widget _walletTable(List<WalletModel> wallets, int total) {
    if (wallets.isEmpty) {
      return pw.Text(
        'Tidak ada data',
        style: const pw.TextStyle(fontSize: 10, color: _grey),
      );
    }
    return _table(
      headers: ['Dompet', 'Jenis', 'Saldo'],
      data: [
        for (final w in wallets)
          [_latin1(w.name), w.type.label, formatCurrency(w.balance)],
        ['Total', '', formatCurrency(total)],
      ],
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      cellAlignments: const {2: pw.Alignment.centerRight},
    );
  }

  /// last data row is rendered as a bold total row
  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> data,
    required Map<int, pw.TableColumnWidth> columnWidths,
    required Map<int, pw.Alignment> cellAlignments,
  }) {
    final totalRow = data.length - 1;
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      columnWidths: columnWidths,
      cellAlignments: cellAlignments,
      headerAlignment: pw.Alignment.centerLeft,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: _primary),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      ),
      textStyleBuilder: (col, value, row) => row == totalRow + 1
          ? pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
          : null,
    );
  }

  /// built-in Helvetica only covers Latin-1; replace other glyphs
  static String _latin1(String text) =>
      String.fromCharCodes(text.runes.map((r) => r <= 0xFF ? r : 0x3F));
}
