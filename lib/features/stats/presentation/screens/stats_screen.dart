import 'dart:io';

import 'package:blacklist_plus_flutter/assets/resources.dart';
import 'package:blacklist_plus_flutter/core/di/dependency_injection.dart';
import 'package:blacklist_plus_flutter/features/stats/data/debt_export_service.dart';
import 'package:blacklist_plus_flutter/features/stats/data/debt_reminder_service.dart';
import 'package:blacklist_plus_flutter/features/stats/data/local_debt.dart';
import 'package:blacklist_plus_flutter/features/stats/data/local_debt_service.dart';
import 'package:blacklist_plus_flutter/features/stats/data/local_stats_service.dart';
import 'package:blacklist_plus_flutter/features/stats/presentation/widgets/add_local_debt_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final LocalStatsService _stats = getIt<LocalStatsService>();
  final LocalDebtService _debts = getIt<LocalDebtService>();

  @override
  void initState() {
    super.initState();
    _stats.addListener(_onChange);
    _debts.addListener(_onChange);
    _stats.recordAppOpen();
  }

  @override
  void dispose() {
    _stats.removeListener(_onChange);
    _debts.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _onAddDebt() async {
    final result = await showAddLocalDebtModal(context: context);
    if (result == null) return;

    if (result.dueDate != null) {
      await getIt<DebtReminderService>().requestPermissionIfNeeded();
    }

    await _debts.add(
      debtorName: result.debtorName,
      amountRub: result.amountRub,
      dueDate: result.dueDate,
      comment: result.comment,
    );

    if (!mounted) return;
    if (result.dueDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Напоминание запланировано за день до возврата (${_fmtFireDate(result.dueDate!)})',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _fmtFireDate(DateTime dueDate) {
    final fire = DateTime(dueDate.year, dueDate.month, dueDate.day - 1, 10);
    return DateFormat('dd.MM в HH:mm', 'ru').format(fire);
  }

  Future<void> _showExportSheet() async {
    if (_debts.debts.isEmpty) return;
    await showModalBottomSheet<void>(
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Экспорт журнала',
                style: AppStyle.manrope(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(AppColors.black),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Файл со списком долгов, суммами и статусами',
                style: AppStyle.manrope(
                  size: 12,
                  weight: FontWeight.w400,
                  color: const Color(AppColors.uiBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: Color(AppColors.primary),
              ),
              title: const Text('Скачать в PDF'),
              subtitle: const Text(
                'Документ для печати или отправки',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _exportAndShare(asExcel: false);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.table_chart_outlined,
                color: Color(AppColors.primary),
              ),
              title: const Text('Скачать в Excel (.xlsx)'),
              subtitle: const Text(
                'Таблица для дальнейшей работы с цифрами',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _exportAndShare(asExcel: true);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAndShare({required bool asExcel}) async {
    final service = getIt<DebtExportService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final File file = asExcel
          ? await service.exportToExcel(_debts.debts)
          : await service.exportToPdf(_debts.debts);

      final mime = asExcel
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'application/pdf';

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mime)],
        subject: 'Журнал долгов',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Не удалось создать файл: $e')),
      );
    }
  }

  Future<void> _showDebugSheet() async {
    await showModalBottomSheet<void>(
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Debug-меню',
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
                Icons.dataset_outlined,
                color: Color(AppColors.primary),
              ),
              title: const Text('Заполнить тестовыми данными'),
              subtitle: const Text('6 долгов: активные, просроченные, оплаченные'),
              onTap: () async {
                Navigator.pop(ctx);
                await getIt<DebtReminderService>().requestPermissionIfNeeded();
                await _debts.seedTestData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Тестовые данные добавлены')),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_outlined,
                color: Color(AppColors.red),
              ),
              title: const Text('Очистить журнал'),
              subtitle: const Text('Удалит все записи и отменит уведомления'),
              onTap: () async {
                Navigator.pop(ctx);
                await _debts.clearAll();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Журнал очищен')),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: Color(AppColors.primary),
              ),
              title: const Text('Тестовое уведомление через 10 сек'),
              subtitle: const Text('Сверните приложение, чтобы увидеть банер'),
              onTap: () async {
                Navigator.pop(ctx);
                final granted = await getIt<DebtReminderService>()
                    .requestPermissionIfNeeded();
                if (!mounted) return;
                if (!granted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Разрешение на уведомления не выдано',
                      ),
                    ),
                  );
                  return;
                }
                await getIt<DebtReminderService>().scheduleTest(seconds: 10);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Уведомление придёт через 10 секунд — сверните приложение',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(LocalDebt debt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: Text(
          'Удалить долг "${debt.debtorName} — ${_money(debt.amountRub)} ₽" из вашего журнала?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Color(AppColors.red)),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _debts.remove(debt.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _stats.snapshot;
    final totals = _debts.totals;
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Header(
              title: 'Статистика',
              showBackButton: true,
              showNotifications: false,
              showAvatar: false,
              onBackPressed: () => Navigator.of(context).maybePop(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      SvgIcons.share,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        _debts.debts.isEmpty
                            ? const Color(AppColors.borderColor)
                            : const Color(AppColors.black),
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: 'Экспорт журнала',
                    onPressed: _debts.debts.isEmpty ? null : _showExportSheet,
                  ),
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(
                        Icons.bug_report_outlined,
                        color: Color(AppColors.uiBorder),
                      ),
                      tooltip: 'Debug',
                      onPressed: _showDebugSheet,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(AppColors.primary),
        foregroundColor: const Color(AppColors.white),
        icon: const Icon(Icons.add),
        label: Text(
          'Добавить долг',
          style: AppStyle.manrope(
            size: 14,
            weight: FontWeight.w600,
            color: const Color(AppColors.white),
          ),
        ),
        onPressed: _onAddDebt,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _StreakCard(streak: snap.streak, activeDays: snap.activeDaysTotal),
            const SizedBox(height: 12),
            _MetricsGrid(snap: snap, totals: totals),
            const SizedBox(height: 12),
            _MoneyCard(totals: totals),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Журнал долгов',
                        style: AppStyle.manrope(
                          size: 16,
                          weight: FontWeight.w700,
                          color: const Color(AppColors.black),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Локальная запись — хранится только на устройстве',
                        style: AppStyle.manrope(
                          size: 12,
                          weight: FontWeight.w400,
                          color: const Color(AppColors.uiBorder),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AddButton(onPressed: _onAddDebt),
              ],
            ),
            const SizedBox(height: 12),
            if (_debts.debts.isEmpty)
              _EmptyDebts()
            else
              for (final debt in _debts.debts) ...[
                _DebtCard(
                  debt: debt,
                  onTogglePaid: () async {
                    if (debt.isPaid) {
                      await _debts.unmarkPaid(debt.id);
                    } else {
                      await _debts.markPaid(debt.id);
                    }
                  },
                  onRemove: () => _confirmRemove(debt),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

String _money(int value) =>
    NumberFormat.decimalPattern('ru').format(value);

class _StreakCard extends StatelessWidget {
  final int streak;
  final int activeDays;
  const _StreakCard({required this.streak, required this.activeDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(AppColors.primary), Color(AppColors.primaryLight)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 30,
              color: Color(AppColors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0
                      ? 'Стрик пока не начат'
                      : 'Стрик использования $streak ${_dayWord(streak)}',
                  style: AppStyle.manrope(
                    size: 16,
                    weight: FontWeight.w700,
                    color: const Color(AppColors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeDays == 0
                      ? 'Откройте приложение завтра, чтобы начать стрик'
                      : 'Всего активных дней: $activeDays',
                  style: AppStyle.manrope(
                    size: 12,
                    weight: FontWeight.w400,
                    color: const Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'дней';
    if (mod10 == 1) return 'день';
    if (mod10 >= 2 && mod10 <= 4) return 'дня';
    return 'дней';
  }
}

class _MetricsGrid extends StatelessWidget {
  final StatsSnapshot snap;
  final DebtTotals totals;
  const _MetricsGrid({required this.snap, required this.totals});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.person_add_alt_1,
                label: 'Добавлено в каталог',
                value: snap.totalAdded.toString(),
                accent: const Color(AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.visibility_outlined,
                label: 'Просмотров профилей',
                value: snap.totalViewed.toString(),
                accent: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Должны вам сейчас',
                value: totals.activeCount.toString(),
                accent: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.check_circle_outline,
                label: 'Уже вернули',
                value: totals.paidCount.toString(),
                accent: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(AppColors.uncomfPayment)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppStyle.manrope(
              size: 22,
              weight: FontWeight.w700,
              color: const Color(AppColors.black),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppStyle.manrope(
              size: 12,
              weight: FontWeight.w500,
              color: const Color(AppColors.uiBorder),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  final DebtTotals totals;
  const _MoneyCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(AppColors.uncomfPayment)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сводка по долгам',
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w600,
              color: const Color(AppColors.uiBorder),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(totals.activeSumRub),
                style: AppStyle.manrope(
                  size: 28,
                  weight: FontWeight.w700,
                  color: const Color(AppColors.black),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '₽',
                  style: AppStyle.manrope(
                    size: 18,
                    weight: FontWeight.w600,
                    color: const Color(AppColors.uiBorder),
                  ),
                ),
              ),
              const Spacer(),
              if (totals.paidSumRub > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'вернули ${_money(totals.paidSumRub)} ₽',
                    style: AppStyle.manrope(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'должны вам сейчас',
            style: AppStyle.manrope(
              size: 12,
              weight: FontWeight.w400,
              color: const Color(AppColors.uiBorder),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final LocalDebt debt;
  final VoidCallback onTogglePaid;
  final VoidCallback onRemove;

  const _DebtCard({
    required this.debt,
    required this.onTogglePaid,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = debt.isPaid;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid
              ? const Color(0xFFBBF7D0)
              : const Color(AppColors.uncomfPayment),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  debt.debtorName,
                  style: AppStyle.manrope(
                    size: 15,
                    weight: FontWeight.w600,
                    color: const Color(AppColors.black),
                  ),
                ),
              ),
              Text(
                '${_money(debt.amountRub)} ₽',
                style: AppStyle.manrope(
                  size: 15,
                  weight: FontWeight.w700,
                  color: isPaid
                      ? const Color(0xFF10B981)
                      : const Color(AppColors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _MetaText(
                icon: Icons.calendar_today_outlined,
                text: 'Создан ${_fmtDate(debt.createdAt)}',
              ),
              if (debt.dueDate != null)
                _MetaText(
                  icon: Icons.event_outlined,
                  text: 'Возврат до ${_fmtDate(debt.dueDate!)}',
                ),
              if (isPaid && debt.paidAt != null)
                _MetaText(
                  icon: Icons.check_circle_outline,
                  text: 'Закрыт ${_fmtDate(debt.paidAt!)}',
                  color: const Color(0xFF10B981),
                ),
            ],
          ),
          if (debt.comment != null) ...[
            const SizedBox(height: 8),
            Text(
              debt.comment!,
              style: AppStyle.manrope(
                size: 13,
                weight: FontWeight.w400,
                height: 1.4,
                color: const Color(AppColors.uiBorder),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTogglePaid,
                  icon: Icon(
                    isPaid ? Icons.undo : Icons.check,
                    size: 16,
                    color: const Color(AppColors.primary),
                  ),
                  label: Text(
                    isPaid ? 'Снова в долг' : 'Долг закрыт',
                    style: AppStyle.manrope(
                      size: 13,
                      weight: FontWeight.w600,
                      color: const Color(AppColors.primary),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(AppColors.primary)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(AppColors.red),
                ),
                tooltip: 'Удалить',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) => DateFormat('dd.MM.yyyy', 'ru').format(dt);
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _MetaText({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(AppColors.uiBorder);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppStyle.manrope(
            size: 12,
            weight: FontWeight.w500,
            color: c,
          ),
        ),
      ],
    );
  }
}

class _EmptyDebts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(AppColors.uncomfPayment)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 36,
            color: Color(AppColors.borderColor),
          ),
          const SizedBox(height: 10),
          Text(
            'Журнал пуст',
            style: AppStyle.manrope(
              size: 14,
              weight: FontWeight.w600,
              color: const Color(AppColors.black),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Нажмите «Добавить долг», чтобы записать первую сумму.',
            textAlign: TextAlign.center,
            style: AppStyle.manrope(
              size: 12,
              weight: FontWeight.w400,
              color: const Color(AppColors.uiBorder),
            ),
          ),
        ],
      ),
    );
  }
}
