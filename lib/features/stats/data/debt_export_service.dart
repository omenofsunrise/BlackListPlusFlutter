import 'dart:io';

import 'package:blacklist_plus_flutter/features/stats/data/local_debt.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DebtExportService {
  static const _kPrimary = PdfColor.fromInt(0xFF2563EB);
  static const _kAccent = PdfColor.fromInt(0xFF60A5FA);
  static const _kTextDark = PdfColor.fromInt(0xFF111827);
  static const _kTextGrey = PdfColor.fromInt(0xFF6B7280);
  static const _kRowBorder = PdfColor.fromInt(0xFFE5E7EB);
  static const _kSuccess = PdfColor.fromInt(0xFF10B981);
  static const _kWarning = PdfColor.fromInt(0xFFF59E0B);

  Future<File> exportToPdf(List<LocalDebt> debts) async {
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    final active = debts.where((d) => !d.isPaid).toList();
    final paid = debts.where((d) => d.isPaid).toList();
    final activeSum = active.fold<int>(0, (s, d) => s + d.amountRub);
    final paidSum = paid.fold<int>(0, (s, d) => s + d.amountRub);

    String money(num v) => NumberFormat.decimalPattern('ru').format(v);
    final today = DateFormat('dd.MM.yyyy', 'ru').format(DateTime.now());

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: theme,
        ),
        build: (context) => [
          _pdfHeader(today, fontBold),
          pw.SizedBox(height: 18),
          _pdfSummary(
            activeCount: active.length,
            paidCount: paid.length,
            activeSum: money(activeSum),
            paidSum: money(paidSum),
            fontBold: fontBold,
          ),
          pw.SizedBox(height: 22),
          if (active.isNotEmpty) ...[
            _pdfSectionTitle('Активные долги', fontBold),
            pw.SizedBox(height: 8),
            _pdfDebtsTable(active, fontBold, isPaidSection: false),
            pw.SizedBox(height: 22),
          ],
          if (paid.isNotEmpty) ...[
            _pdfSectionTitle('Закрытые долги', fontBold),
            pw.SizedBox(height: 8),
            _pdfDebtsTable(paid, fontBold, isPaidSection: true),
            pw.SizedBox(height: 22),
          ],
          if (active.isEmpty && paid.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Журнал пуст',
                style: pw.TextStyle(font: fontBold, color: _kTextGrey),
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'Документ сформирован приложением «ЧС+» — личный журнал долгов.',
              style: pw.TextStyle(fontSize: 10, color: _kTextGrey),
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/Zhurnal_dolgov_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> exportToExcel(List<LocalDebt> debts) async {
    final book = Excel.createExcel();
    final sheet = book['Журнал долгов'];
    final defaultSheet = book.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Журнал долгов') {
      book.delete(defaultSheet);
    }

    final headers = [
      '№',
      'Имя должника',
      'Сумма, ₽',
      'Статус',
      'Дата записи',
      'Дата возврата',
      'Дата закрытия',
      'Комментарий',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.fromHexString('FF2563EB'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    String fmt(DateTime? d) =>
        d == null ? '' : DateFormat('dd.MM.yyyy', 'ru').format(d);

    for (var i = 0; i < debts.length; i++) {
      final d = debts[i];
      final row = i + 1;
      final values = <CellValue>[
        IntCellValue(row),
        TextCellValue(d.debtorName),
        IntCellValue(d.amountRub),
        TextCellValue(d.isPaid ? 'Закрыт' : 'Активный'),
        TextCellValue(fmt(d.createdAt)),
        TextCellValue(fmt(d.dueDate)),
        TextCellValue(fmt(d.paidAt)),
        TextCellValue(d.comment ?? ''),
      ];
      for (var c = 0; c < values.length; c++) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        ).value = values[c];
      }
    }

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 26);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 36);

    final bytes = book.encode() ?? <int>[];
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/Zhurnal_dolgov_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  pw.Widget _pdfHeader(String today, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _kAccent, width: 2),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Журнал долгов',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 22,
              color: _kPrimary,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Дата формирования: $today',
            style: pw.TextStyle(fontSize: 11, color: _kTextGrey),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSummary({
    required int activeCount,
    required int paidCount,
    required String activeSum,
    required String paidSum,
    required pw.Font fontBold,
  }) {
    pw.Widget tile(String label, String value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kRowBorder),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 10, color: _kTextGrey),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                value,
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: color),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        tile('Активных', '$activeCount шт.', _kWarning),
        pw.SizedBox(width: 10),
        tile('Сумма к получению', '$activeSum ₽', _kTextDark),
        pw.SizedBox(width: 10),
        tile('Закрытых', '$paidCount шт.', _kSuccess),
        pw.SizedBox(width: 10),
        tile('Уже вернули', '$paidSum ₽', _kTextDark),
      ],
    );
  }

  pw.Widget _pdfSectionTitle(String text, pw.Font fontBold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 4,
          height: 18,
          color: _kAccent,
          margin: const pw.EdgeInsets.only(right: 8),
        ),
        pw.Text(
          text,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 16,
            color: _kPrimary,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfDebtsTable(
    List<LocalDebt> debts,
    pw.Font fontBold, {
    required bool isPaidSection,
  }) {
    String money(num v) => NumberFormat.decimalPattern('ru').format(v);
    String fmt(DateTime? d) =>
        d == null ? '—' : DateFormat('dd.MM.yyyy', 'ru').format(d);

    final headers = isPaidSection
        ? ['№', 'Имя должника', 'Сумма', 'Создан', 'Закрыт', 'Комментарий']
        : ['№', 'Имя должника', 'Сумма', 'Создан', 'Возврат до', 'Комментарий'];

    final rows = <List<String>>[];
    for (var i = 0; i < debts.length; i++) {
      final d = debts[i];
      rows.add([
        '${i + 1}',
        d.debtorName,
        '${money(d.amountRub)} ₽',
        fmt(d.createdAt),
        isPaidSection ? fmt(d.paidAt) : fmt(d.dueDate),
        d.comment ?? '',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _kRowBorder, width: 0.5),
      headerStyle: pw.TextStyle(
        font: fontBold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: _kPrimary),
      cellStyle: const pw.TextStyle(fontSize: 10, color: _kTextDark),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerLeft,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(2.4),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.4),
        5: const pw.FlexColumnWidth(2.6),
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      headers: headers,
      data: rows,
    );
  }
}
