import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../data/models/report_data.dart';
import '../services/pdf_report_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key, required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export PDF')),
      body: PdfPreview(
        build: (format) => PdfReportService.build(data, format: format),
        pdfFileName: PdfReportService.fileName(data),
        initialPageFormat: PdfPageFormat.a4,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
