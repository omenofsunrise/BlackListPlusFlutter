import 'dart:io';
import 'package:blacklist_plus_flutter/assets/resources.dart';
import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/calc/data/calc_preset.dart';
import 'package:blacklist_plus_flutter/features/calc/data/calc_preset_service.dart';
import 'package:blacklist_plus_flutter/features/calc/data/calculation_mode.dart';
import 'package:blacklist_plus_flutter/features/calc/widgets/calc_preset_modal.dart';
import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:waypay_flutter_library/waypay_styles.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final GlobalKey _headerTitleKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  final _sumController = TextEditingController();
  final _monthsController = TextEditingController();
  final _initialController = TextEditingController();
  final _percentController = TextEditingController();
  final _roundController = TextEditingController();
  final FocusNode _monthsFocusNode = FocusNode();

  final CalcPresetService _presetService = getIt<CalcPresetService>();

  DateTime _startDate = DateTime.now().add(const Duration(days: 31));

  double monthlyPayment = 0;
  double debt = 0;
  double overpayment = 0;
  double total = 0;
  DateTime lastPaymentDate = DateTime.now();

  CalculationMode _calculationMode = CalculationMode.standard;
  static const int _minMonths = 2;
  static const int _maxMonths = 999999;

  @override
  void initState() {
    super.initState();
    _monthsController.text = _minMonths.toString();
    _roundController.text = '50';
    _monthsController.addListener(_handleMonthsChanged);
    _sumController.addListener(_calculate);
    _initialController.addListener(_calculate);
    _presetService.addListener(_onPresetsChanged);
    _percentController.addListener(_calculate);
    _roundController.addListener(_calculate);
  }

  void _showCalculationModeMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    const double popupWidth = 220;

    Offset? anchor;
    Size? anchorSize;
    final RenderBox? titleBox =
        _headerTitleKey.currentContext?.findRenderObject() as RenderBox?;
    if (titleBox != null) {
      anchor = titleBox.localToGlobal(Offset.zero, ancestor: overlay);
      anchorSize = titleBox.size;
    } else {
      final RenderBox button = context.findRenderObject() as RenderBox;
      anchor = button.localToGlobal(
        Offset(button.size.width / 2, button.size.height),
        ancestor: overlay,
      );
      anchorSize = Size.zero;
    }

    final double desiredLeft =
        anchor.dx +
        (anchorSize.width.isFinite ? (anchorSize.width - popupWidth) / 2 : 0);
    final double clampedLeft = desiredLeft.clamp(
      16.0,
      overlay.size.width - popupWidth - 16.0,
    );
    final double top = anchor.dy + anchorSize.height + 8;
    final double right = overlay.size.width - clampedLeft - popupWidth;
    final double bottom = overlay.size.height - top;
    final RelativeRect position = RelativeRect.fromLTRB(
      clampedLeft,
      top,
      right,
      bottom,
    );

    showMenu<CalculationMode>(
      context: context,
      position: position,
      color: Color(AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        _buildCalculationModeItem(
          CalculationMode.standard,
          'Стандартный (на всю сумму)',
        ),
        _buildCalculationModeItem(
          CalculationMode.afterInitial,
          'Надбавка после вычета взноса',
        ),
        _buildCalculationModeItem(
          CalculationMode.monthlyPercent,
          'Процент за 1 месяц (x месяцев)',
        ),
      ],
    );
  }

  void _handleMonthsChanged() {
    final raw = _monthsController.text.trim();
    if (raw.isEmpty) return;
    final parsed = int.tryParse(raw);
    if (parsed == null) return;
    if (parsed < _minMonths || parsed > _maxMonths) return;
    _calculate();
  }

  void _updateMonths(int months) {
    final clamped = months.clamp(_minMonths, _maxMonths);
    final text = clamped.toString();
    _monthsController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _calculate();
  }

  PopupMenuItem<CalculationMode> _buildCalculationModeItem(
    CalculationMode mode,
    String title,
  ) {
    final isSelected = _calculationMode == mode;
    return PopupMenuItem<CalculationMode>(
      value: mode,
      onTap: () {
        if (mode != _calculationMode) {
          setState(() {
            _calculationMode = mode;
            _calculate();
          });
        }
      },
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(AppColors.primary)
                    : const Color(AppColors.borderColor),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                        color: Color(AppColors.primary),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppStyle.manrope(
                size: 14,
                weight: FontWeight.w400,
                height: 24 / 14,
                color: isSelected
                    ? const Color(AppColors.black)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _monthsController.removeListener(_handleMonthsChanged);
    _presetService.removeListener(_onPresetsChanged);
    _sumController.dispose();
    _monthsController.dispose();
    _initialController.dispose();
    _percentController.dispose();
    _roundController.dispose();
    _monthsFocusNode.dispose();
    super.dispose();
  }

  void _onPresetsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _createPreset() async {
    final result = await showCalcPresetModal(context: context);
    if (result == null) return;
    await _presetService.add(
      title: result.title,
      amount: result.amount,
      months: result.months,
      initial: result.initial,
      percent: result.percent,
      round: result.round,
      mode: result.mode,
    );
  }

  Future<void> _editPreset(CalcPreset preset) async {
    final result = await showCalcPresetModal(
      context: context,
      editing: preset,
    );
    if (result == null) return;
    await _presetService.update(
      preset.copyWith(
        title: result.title,
        amount: result.amount,
        months: result.months,
        initial: result.initial,
        percent: result.percent,
        round: result.round,
        mode: result.mode,
      ),
    );
  }

  Future<void> _showPresetMenu(CalcPreset preset) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(AppColors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(AppColors.uncomfPayment),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                preset.title,
                style: AppStyle.manrope(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(AppColors.black),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(AppColors.primary),
              ),
              title: const Text('Редактировать'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(AppColors.red),
              ),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'edit') {
      await _editPreset(preset);
    } else if (action == 'delete') {
      await _presetService.remove(preset.id);
    }
  }

  Rect? _sharePositionOrigin() {
    final RenderBox? box =
        _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) {
      final Size screen = MediaQuery.of(context).size;
      return Rect.fromCenter(
        center: Offset(screen.width / 2, screen.height / 2),
        width: 1,
        height: 1,
      );
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _generateAndSharePdf() async {
    try {
      final bytes = await _buildPdfBytes();

      final dir = await getTemporaryDirectory();
      final filename =
          'ChS-Plus-raschet-${DateFormat('dd.MM.yyyy').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Расчёт рассрочки',
        sharePositionOrigin: _sharePositionOrigin(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось создать PDF: $e')));
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    final doc = pw.Document();

    const primary = PdfColor.fromInt(0xFF007D88);
    const accent = PdfColor.fromInt(0xFF25CBA1);
    const white = PdfColors.white;
    const textDark = PdfColor.fromInt(0xFF111827);
    const textGrey = PdfColor.fromInt(0xFF6B7280);
    const rowBorder = PdfColor.fromInt(0xFFE5E7EB);
    const barDebt = PdfColor.fromInt(0xFF007D88);
    const barOver = PdfColor.fromInt(0xFF25CBA1);

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    String money(num v) => NumberFormat('#,##0', 'ru').format(v);

    final amount =
        double.tryParse(_sumController.text.replaceAll(' ', '')) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;
    final initial =
        double.tryParse(_initialController.text.replaceAll(' ', '')) ?? 0;
    final displayAmount = money(amount);
    final displayInitial = money(initial);
    final displayMonths = months.toString();
    final displayStart = DateFormat('dd.MM.yyyy', 'ru').format(_startDate);

    final displayTotal = money(total);
    final displayDebt = money(debt);
    final displayMonthly = money(monthlyPayment);
    final displayLastMonth = DateFormat(
      'LLLL yyyy',
      'ru',
    ).format(lastPaymentDate);

    final sumForBar = (debt + overpayment);
    final debtPct = sumForBar > 0 ? (debt / sumForBar) : 0.5;

    final List<List<String>> scheduleRows = [];
    if (months > 0 && debt > 0 && monthlyPayment > 0) {
      double remaining = debt;
      for (int i = 0; i < months; i++) {
        final paymentDate = DateTime(
          _startDate.year,
          _startDate.month + i,
          _startDate.day,
        );
        final isLast = i == months - 1;
        double pay;
        if (isLast) {
          pay = remaining > 0 ? remaining : 0;
        } else {
          pay = monthlyPayment <= remaining ? monthlyPayment : remaining;
        }
        remaining -= pay;
        if (remaining < 0) remaining = 0;
        scheduleRows.add([
          '${i + 1}',
          DateFormat('dd.MM.yyyy', 'ru').format(paymentDate),
          '${money(pay)} ₽',
          '${money(remaining)} ₽',
        ]);
      }
    }

    pw.Widget card(pw.Widget child) => pw.Container(
      decoration: pw.BoxDecoration(
        color: white,
        borderRadius: pw.BorderRadius.circular(12),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x14000000),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const PdfPoint(0, 2),
          ),
        ],
      ),
      padding: const pw.EdgeInsets.all(20),
      margin: const pw.EdgeInsets.only(bottom: 30),
      child: child,
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          theme: theme,
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: white),
          ),
        ),
        build: (context) => [
          card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: accent, width: 2),
                          ),
                        ),
                        child: pw.Text(
                          'Расчёт рассрочки',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: primary,
                          ),
                        ),
                      ),
                      pw.Text(
                        'Дата формирования: ${DateFormat('dd.MM.yyyy', 'ru').format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 14, color: textGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 20,
                      color: accent,
                      margin: const pw.EdgeInsets.only(right: 10),
                    ),
                    pw.Text(
                      'Входные данные',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: primary,
                        font: fontBold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'Сумма рассрочки: ',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFF374151),
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: '$displayAmount ₽',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'Количество месяцев: ',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFF374151),
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: displayMonths,
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'Начало выплат: ',
                                    style: pw.TextStyle(
                                      color: PdfColor.fromInt(0xFF374151),
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: displayStart,
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      color: textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          card(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 20,
                      color: accent,
                      margin: const pw.EdgeInsets.only(right: 10),
                    ),
                    pw.Text(
                      'Результаты расчёта',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: primary,
                        font: fontBold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                _pdfRow(
                  'Общая стоимость',
                  '$displayTotal ₽',
                  rowBorder,
                  textDark,
                ),
                _pdfRow('Взнос', '$displayInitial ₽', rowBorder, textDark),
                _pdfRow('Сумма долга', '$displayDebt ₽', rowBorder, textDark),
                _pdfRow(
                  'Ежемесячный платёж',
                  '$displayMonthly ₽',
                  rowBorder,
                  textDark,
                ),
                _pdfRow(
                  'Последний месяц оплаты',
                  displayLastMonth,
                  null,
                  textDark,
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: barOver,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      height: 10,
                      width:
                          pw.FractionColumnWidth(debtPct).value *
                          PdfPageFormat.a4.availableWidth,
                      decoration: pw.BoxDecoration(
                        color: barDebt,
                        borderRadius: const pw.BorderRadius.horizontal(
                          left: pw.Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (scheduleRows.isNotEmpty) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 4,
                    height: 20,
                    color: accent,
                    margin: const pw.EdgeInsets.only(right: 10),
                  ),
                  pw.Text(
                    'График платежей',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: primary,
                      font: fontBold,
                    ),
                  ),
                ],
              ),
            ),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: rowBorder, width: 0.5),
              headerStyle: pw.TextStyle(
                font: fontBold,
                color: white,
                fontSize: 11,
              ),
              headerDecoration: const pw.BoxDecoration(color: primary),
              cellStyle: pw.TextStyle(fontSize: 11, color: textDark),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headerAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              headers: ['№', 'Дата платежа', 'Платёж', 'Остаток'],
              data: scheduleRows,
            ),
            pw.SizedBox(height: 30),
          ],

          card(
            pw.Center(
              child: pw.Text(
                '© ${DateTime.now().year} ЧС+. Все права защищены.',
                style: pw.TextStyle(fontSize: 12, color: textGrey),
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfRow(
    String left,
    String right,
    PdfColor? underline,
    PdfColor rightColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: underline != null
          ? pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: underline)),
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            left,
            style: const pw.TextStyle(color: PdfColor.fromInt(0xFF374151)),
          ),
          pw.Text(
            right,

            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: rightColor,
            ),
          ),
        ],
      ),
    );
  }

  double roundUp(double value, double increment) {
    if (increment == 0) return value;
    return (value / increment).ceil() * increment;
  }

  void _calculate() {
    final ws = RegExp(r'\s');
    final amount =
        double.tryParse(_sumController.text.replaceAll(ws, '')) ?? 0;
    final months = int.tryParse(_monthsController.text.replaceAll(ws, '')) ?? 1;
    final initial =
        double.tryParse(_initialController.text.replaceAll(ws, '')) ?? 0;
    final percent =
        double.tryParse(_percentController.text.replaceAll(ws, '')) ?? 0;
    final round =
        double.tryParse(_roundController.text.replaceAll(ws, '')) ?? 0;

    if (months < 1 || months > 360) return;

    double totalAmount;
    double overpaymentValue;

    switch (_calculationMode) {
      case CalculationMode.standard:
        totalAmount = amount * (1 + percent / 100);
        overpaymentValue = totalAmount - amount;
        break;

      case CalculationMode.afterInitial:
        final amountAfterInitial = amount - initial;
        totalAmount = initial + (amountAfterInitial * (1 + percent / 100));
        overpaymentValue = totalAmount - amount;
        break;

      case CalculationMode.monthlyPercent:
        totalAmount = amount * (1 + (percent * 12) / 100);
        overpaymentValue = totalAmount - amount;
        break;
    }

    final roundedTotalAmount = roundUp(totalAmount, round);
    final roundedOverpayment = roundUp(overpaymentValue, round);

    final validInitial = initial > roundedTotalAmount
        ? roundedTotalAmount
        : initial;

    final debtValue = roundedTotalAmount - validInitial;
    final roundedDebt = roundUp(debtValue, round);

    final monthlyRaw = roundedDebt / months;
    monthlyPayment = roundUp(monthlyRaw, round);

    final lastPayment = DateTime(
      _startDate.year,
      _startDate.month + months - 1,
      _startDate.day,
    );

    setState(() {
      total = roundedTotalAmount;
      overpayment = roundedOverpayment;
      debt = roundedDebt;
      lastPaymentDate = lastPayment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: 'Калькулятор',
              showBackButton: false,
              showNotifications: false,
              showAvatar: false,
              onBackPressed: () => Navigator.of(context).maybePop(),
              titleKey: _headerTitleKey,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.description_outlined,
                      size: 24,
                      color: Color(AppColors.black),
                    ),
                    tooltip: 'Шаблоны документов',
                    onPressed: () => context.pushNamed(
                      Routes.templatesScreen.toName,
                    ),
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      SvgIcons.calcMode,
                      width: 24,
                      height: 24,
                    ),
                    tooltip: 'Переключить режим',
                    onPressed: () => _showCalculationModeMenu(context),
                  ),
                  IconButton(
                    key: _shareButtonKey,
                    icon: SvgPicture.asset(
                      SvgIcons.share,
                      width: 24,
                      height: 24,
                    ),
                    tooltip: 'Экспорт в PDF',
                    onPressed: _generateAndSharePdf,
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      SvgIcons.refresh,
                      width: 24,
                      height: 24,
                    ),
                    tooltip: 'Сбросить',
                    onPressed: () {
                      _sumController.clear();
                      _initialController.clear();
                      _percentController.clear();
                      _roundController.clear();
                      _updateMonths(_minMonths);
                      setState(() {
                        monthlyPayment = 0;
                        debt = 0;
                        overpayment = 0;
                        total = 0;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [_buildInputSection(), _buildResultSection()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyPreset(CalcPreset preset) {
    _sumController.text = _formatCurrency(preset.amount.toDouble());
    _initialController.text = preset.initial == 0
        ? ''
        : _formatCurrency(preset.initial.toDouble());
    _percentController.text = preset.percent.toString();
    _roundController.text = preset.round.toString();
    setState(() {
      _calculationMode = preset.mode;
    });
    _updateMonths(preset.months);
  }

  Widget _buildPresetsSection() {
    final presets = _presetService.presets;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Категории наценки',
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w600,
              color: const Color(AppColors.black),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Тап — применить, долгое нажатие — редактировать',
            style: AppStyle.manrope(
              size: 11,
              weight: FontWeight.w400,
              color: const Color(AppColors.uiBorder),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AddPresetChip(onTap: _createPreset);
                }
                final preset = presets[index - 1];
                return _PresetChip(
                  label: '${preset.title} · ${preset.percent}%',
                  onTap: () => _applyPreset(preset),
                  onLongPress: () => _showPresetMenu(preset),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        _buildPresetsSection(),
        _buildFloatingTextField(
          controller: _sumController,
          hint: 'Сумма рассрочки, ₽',
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(
              thousandSeparator: ThousandSeparator.Space,
              mantissaLength: 0,
              trailingSymbol: '',
            ),
          ],
        ),
        _buildFloatingTextField(
          controller: _initialController,
          hint: 'Первоначальный взнос, ₽',
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(
              thousandSeparator: ThousandSeparator.Space,
              mantissaLength: 0,
              trailingSymbol: '',
            ),
          ],
        ),
        _buildDatePickerField(),
        _buildFloatingTextField(
          controller: _monthsController,
          hint: 'Количество месяцев',
          keyboardType: const TextInputType.numberWithOptions(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          focusNode: _monthsFocusNode,
          onTap: () {
            final text = _monthsController.text;
            _monthsController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: text.length,
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Expanded(
                child: _buildFloatingTextField(
                  controller: _percentController,
                  hint: 'Надбавка, %',
                  keyboardType: const TextInputType.numberWithOptions(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFloatingTextField(
                  controller: _roundController,
                  hint: 'Округлять до, ₽',
                  keyboardType: const TextInputType.numberWithOptions(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ModalTextField(
        controller: controller,
        label: hint,
        keyboardType: keyboardType,
        onTap: onTap,
        inputFormatters: inputFormatters,
        readOnly: false,
      ),
    );
  }

  Widget _buildPickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    bool showClear = false,
    VoidCallback? onClear,
    Widget? customSuffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ModalTextField(
        controller: controller,
        label: label,
        hintText: label,
        readOnly: true,
        onTap: onTap,
        suffixIcon: _buildDropdownSuffix(
          showClear: showClear,
          onClear: onClear,
          customIcon: customSuffixIcon,
        ),
        suffixIconConstraints: const BoxConstraints(
          minHeight: 24,
          minWidth: 32,
          maxWidth: 60,
        ),
      ),
    );
  }

  Widget _buildDropdownSuffix({
    bool showClear = false,
    VoidCallback? onClear,
    Widget? customIcon,
  }) {
    const arrow = Icon(
      Icons.keyboard_arrow_down_rounded,
      color: Color(AppColors.uiBorder),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showClear)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.close,
                size: 16,
                color: Color(AppColors.uiBorder),
              ),
            ),
          ),
        customIcon ?? arrow,
      ],
    );
  }

  Widget _buildDatePickerField() {
    final controller = TextEditingController(
      text: DateFormat('dd.MM.yyyy').format(_startDate),
    );

    return _buildPickerField(
      controller: controller,
      label: 'Начало выплат',
      onTap: () async {
        await showDialog<void>(
          context: context,
          builder: (_) => CustomCalendar(
            initialDate: _startDate,
            prefix: 'Начало выплат:',
            onDateSelected: (date) {
              setState(() => _startDate = date);
              controller.text = DateFormat('dd.MM.yyyy').format(_startDate);
              _calculate();
            },
          ),
        );
      },
      customSuffixIcon: Transform.translate(
        offset: const Offset(-8, 0),
        child: SvgPicture.asset(
          SvgIcons.calendar,
          width: 20,
          height: 20,
          color: const Color(0xFF6B717C),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Результаты расчёта',
              style: AppStyle.manrope(size: 22, weight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _buildResultRow(
              'Ежемесячный платеж',
              '${_formatCurrency(monthlyPayment)} ₽',
            ),
            _buildResultRow('Надбавка %', '${_formatPercentValue()}%'),
            const SizedBox(height: 8),
            _buildResultRow(
              'Сумма долга',
              '${_formatCurrency(debt)} ₽',
              leadingDot: const Color(AppColors.primary),
            ),
            _buildResultRow(
              'Переплата',
              '${_formatCurrency(overpayment)} ₽',
              leadingDot: const Color(0xFF6CD5C6),
            ),
            _buildResultRow('Общая сумма', '${_formatCurrency(total)} ₽'),
            _buildResultRow(
              'Последний месяц оплаты',
              DateFormat('LLLL yyyy', 'ru').format(lastPaymentDate),
            ),
            const SizedBox(height: 12),
            PaymentLineBar(debt: debt, overpayment: overpayment, total: total),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? leadingDot}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (leadingDot != null) ...[
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: leadingDot,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
          Expanded(
            child: Text(
              label,
              style: AppStyle.manrope(
                size: 15,
                weight: FontWeight.w400,
                color: const Color(AppColors.uiBorder),
              ),
            ),
          ),
          Text(
            value,
            style: AppStyle.manrope(size: 15, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatPercentValue() {
    final text = _percentController.text.trim();
    if (text.isEmpty) return '0';
    final sanitized = text.replaceAll(',', '.');
    final value = double.tryParse(sanitized) ?? 0;
    return NumberFormat('0.#', 'ru').format(value);
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'ru');
    return formatter.format(value);
  }
}

class PaymentLineBar extends StatelessWidget {
  final double debt;
  final double overpayment;
  final double total;

  const PaymentLineBar({
    super.key,
    required this.debt,
    required this.overpayment,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final double sum = debt + overpayment;
    final double debtFraction = sum == 0 ? 0 : (debt / sum).clamp(0.0, 1.0);
    final double overpaymentFraction = sum == 0
        ? 0
        : (overpayment / sum).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              color: const Color(0xFFD7DBE2),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final debtWidth = totalWidth * debtFraction;
                final overWidth = totalWidth * overpaymentFraction;
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: debtWidth,
                        height: 10,
                        color: const Color(AppColors.primary),
                      ),
                    ),
                    Positioned(
                      left: debtWidth,
                      child: Container(
                        width: overWidth,
                        height: 10,
                        color: const Color(0xFF6CD5C6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PresetChip({
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.greenTie),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_outlined,
                size: 16,
                color: Color(AppColors.primary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppStyle.manrope(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPresetChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPresetChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(AppColors.white),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(AppColors.primary),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                size: 16,
                color: Color(AppColors.primary),
              ),
              const SizedBox(width: 6),
              Text(
                'Создать',
                style: AppStyle.manrope(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
