import 'dart:io';

import 'package:blacklist_plus_flutter/features/stats/data/local_debt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Локальные напоминания о датах возврата долга.
/// Планирует пуш за день до dueDate в 10:00 утра по локальному времени.
class DebtReminderService {
  static const _channelId = 'debt_reminders';
  static const _channelName = 'Напоминания о долгах';
  static const _channelDescription =
      'Уведомления за день до даты возврата долга';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Запрашивает у пользователя разрешение на уведомления.
  /// На iOS показывает системный диалог, на Android (13+) — runtime permission.
  /// Возвращает true, если пользователь дал согласие.
  Future<bool> requestPermissionIfNeeded() async {
    await init();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    return false;
  }

  /// Планирует уведомление за день до dueDate в 10:00 утра.
  /// Если dueDate в прошлом или уже в течение ближайших 24 часов — не планирует.
  Future<void> schedule(LocalDebt debt) async {
    await init();
    if (debt.dueDate == null || debt.isPaid) return;
    final fireDate = _computeFireDate(debt.dueDate!);
    if (fireDate == null) return;

    final tzFire = tz.TZDateTime.from(fireDate, tz.local);
    final money = NumberFormat.decimalPattern('ru').format(debt.amountRub);
    final body =
        '${debt.debtorName} должен вернуть $money ₽ ${_relativeWhen(debt.dueDate!)}';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        _idFor(debt.id),
        'Напоминание о долге',
        body,
        tzFire,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: debt.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DebtReminderService.schedule failed: $e');
      }
    }
  }

  Future<void> cancel(String debtId) async {
    await init();
    try {
      await _plugin.cancel(_idFor(debtId));
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Только для отладки: показывает тестовое уведомление через [seconds] секунд.
  Future<void> scheduleTest({int seconds = 10}) async {
    await init();
    final fire = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.zonedSchedule(
      99999,
      'Тестовое напоминание',
      'Если вы это видите — уведомления работают',
      fire,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  DateTime? _computeFireDate(DateTime dueDate) {
    final fire = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      10,
      0,
    );
    if (fire.isBefore(DateTime.now())) return null;
    return fire;
  }

  String _relativeWhen(DateTime dueDate) {
    final today = DateTime.now();
    final diff = DateTime(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (diff == 1) return 'завтра';
    if (diff == 0) return 'сегодня';
    return DateFormat('dd.MM.yyyy', 'ru').format(dueDate);
  }

  /// debt.id — строка из microsecondsSinceEpoch.toString(),
  /// нужен int в пределах int32 для notifications.
  int _idFor(String debtId) {
    final n = int.tryParse(debtId);
    if (n == null) return debtId.hashCode & 0x7fffffff;
    return n.remainder(2147483647).toInt().abs();
  }
}
