// lib/services/notification_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/notification_model.dart';
import 'app_noti_services.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _chanMedication  = 'medication_reminders';
  static const _chanAppointment = 'appointment_reminders';
  static const _chanStock       = 'stock_alerts';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INIT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final tzName = _deviceTimezone();
      if (tzName.startsWith('+') || tzName.startsWith('-')) {
        tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
      } else {
        tz.setLocalLocation(tz.getLocation(tzName));
      }
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _createChannel(
        id: _chanMedication,
        name: 'Medication Reminders',
        description: 'Reminders to take your medication on time',
        importance: Importance.high);
    await _createChannel(
        id: _chanAppointment,
        name: 'Appointment Reminders',
        description: 'Upcoming appointment notifications',
        importance: Importance.high);
    await _createChannel(
        id: _chanStock,
        name: 'Stock Alerts',
        description: 'Low or out-of-stock medication alerts',
        importance: Importance.defaultImportance);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('[NotificationService] Initialized ✓');
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MEDICATION NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> scheduleMedication({
    required String     medId,
    required String     medName,
    required String     dosage,
    required bool       isReminderOn,
    required TimeOfDay  reminderTime,
    required TimeOfDay? eveningReminderTime,
    required String     frequency,
    required List<int>  weeklyDays,
    required int        stockCurrent,
    required int        stockMax,
  }) async {
    await cancelMedication(medId);
    if (!isReminderOn) return;

    final doseLabel = dosage.isNotEmpty ? '$dosage ' : '';
    final title     = '💊 Time to take $medName';
    final body      = 'Take your $doseLabel${medName.toLowerCase()} now.';

    // ── Phone notification ─────────────────────────────────────────────────
    await _scheduleDailyOrWeekly(
      id:         _medId(medId),
      channelId:  _chanMedication,
      title:      title,
      body:       body,
      time:       reminderTime,
      frequency:  frequency,
      weeklyDays: weeklyDays,
    );

    // ── In-app notification (Firestore bell) ───────────────────────────────
    await _writeInApp(
      title: title,
      body:  body,
      type:  NotificationType.general,
      metadata: {'medId': medId, 'category': 'medication'},
    );

    // ── Evening dose (Twice Daily) ─────────────────────────────────────────
    if (frequency == 'Twice Daily') {
      final evening = eveningReminderTime ??
          TimeOfDay(
            hour:   (reminderTime.hour + 8).clamp(0, 23),
            minute: reminderTime.minute,
          );
      final eTitle = '💊 Evening dose — $medName';
      final eBody  =
          'Time for your evening $doseLabel${medName.toLowerCase()}.';

      await _scheduleDailyOrWeekly(
        id:         _medIdEvening(medId),
        channelId:  _chanMedication,
        title:      eTitle,
        body:       eBody,
        time:       evening,
        frequency:  'Daily',
        weeklyDays: [],
      );

      await _writeInApp(
        title: eTitle,
        body:  eBody,
        type:  NotificationType.general,
        metadata: {'medId': medId, 'category': 'medication_evening'},
      );
    }

    // ── Stock alerts ───────────────────────────────────────────────────────
    if (stockMax > 0) {
      final pct = stockCurrent / stockMax;

      if (stockCurrent == 0) {
        const sTitle = '⛔ Out of stock';
        final sBody  = '$medName is out of stock. Please refill.';
        await _showImmediate(
            id: _medIdStock(medId), channelId: _chanStock,
            title: sTitle, body: sBody);
        await _writeInApp(
          title: sTitle, body: sBody,
          type: NotificationType.general,
          metadata: {'medId': medId, 'category': 'stock_out'},
        );
      } else if (pct <= 0.2) {
        final sTitle = '⚠️ Low stock — $medName';
        final sBody  =
            'Only $stockCurrent unit(s) left. Consider refilling soon.';
        await _showImmediate(
            id: _medIdStock(medId), channelId: _chanStock,
            title: sTitle, body: sBody);
        await _writeInApp(
          title: sTitle, body: sBody,
          type: NotificationType.general,
          metadata: {'medId': medId, 'category': 'stock_low'},
        );
      }
    }

    debugPrint('[NotificationService] Scheduled medication: $medName');
  }

  static Future<void> cancelMedication(String medId) async {
    await _plugin.cancel(_medId(medId));
    await _plugin.cancel(_medIdEvening(medId));
    await _plugin.cancel(_medIdStock(medId));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // APPOINTMENT NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> scheduleAppointment({
    required String   apptId,
    required String   title,
    required String   personInCharge,
    required DateTime dateTime,
    required int      reminderMinutes,
  }) async {
    await cancelAppointment(apptId);

    final now          = DateTime.now();
    final reminderTime = dateTime.subtract(Duration(minutes: reminderMinutes));
    final oneDayBefore = dateTime.subtract(const Duration(days: 1));
    final person =
        personInCharge.isNotEmpty ? ' with $personInCharge' : '';

    // ── X-minutes-before ──────────────────────────────────────────────────
    if (reminderTime.isAfter(now)) {
      final aTitle =
          '📅 Appointment in ${_reminderLabel(reminderMinutes)}';
      final aBody = '$title$person starts soon.';

      await _scheduleOnce(
          id: _apptId(apptId), channelId: _chanAppointment,
          title: aTitle, body: aBody, dateTime: reminderTime);

      await _writeInApp(
        title: aTitle, body: aBody,
        type: NotificationType.general,
        metadata: {'apptId': apptId, 'category': 'appointment_soon'},
      );
    }

    // ── 1-day-before ──────────────────────────────────────────────────────
    if (oneDayBefore.isAfter(now) && reminderMinutes < 1440) {
      final dTitle = '📅 Appointment tomorrow — $title';
      final dBody  =
          'You have $title$person tomorrow at ${_fmtTime(dateTime)}.';

      await _scheduleOnce(
          id: _apptIdDay(apptId), channelId: _chanAppointment,
          title: dTitle, body: dBody, dateTime: oneDayBefore);

      await _writeInApp(
        title: dTitle, body: dBody,
        type: NotificationType.general,
        metadata: {'apptId': apptId, 'category': 'appointment_tomorrow'},
      );
    }

    debugPrint('[NotificationService] Scheduled appointment: $title');
  }

  static Future<void> cancelAppointment(String apptId) async {
    await _plugin.cancel(_apptId(apptId));
    await _plugin.cancel(_apptIdDay(apptId));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WRITE IN-APP NOTIFICATION TO FIRESTORE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> _writeInApp({
    required String                title,
    required String                body,
    required NotificationType      type,
    Map<String, dynamic>           metadata = const {},
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await AppNotificationService.instance.addNotification(
      uid,
      AppNotification(
        id:        '',
        type:      type,
        title:     title,
        body:      body,
        isRead:    false,
        createdAt: DateTime.now(),
        metadata:  metadata,
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INTERNAL HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> _scheduleDailyOrWeekly({
    required int       id,
    required String    channelId,
    required String    title,
    required String    body,
    required TimeOfDay time,
    required String    frequency,
    required List<int> weeklyDays,
  }) async {
    final details = _details(channelId);
    if (frequency == 'Weekly' && weeklyDays.isNotEmpty) {
      for (final weekday in weeklyDays) {
        await _plugin.zonedSchedule(
          id + weekday, title, body,
          _nextWeekday(weekday, time), details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      await _plugin.zonedSchedule(
        id, title, body,
        _nextTime(time), details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> _scheduleOnce({
    required int      id,
    required String   channelId,
    required String   title,
    required String   body,
    required DateTime dateTime,
  }) async {
    await _plugin.zonedSchedule(
      id, title, body,
      tz.TZDateTime.from(dateTime, tz.local),
      _details(channelId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> _showImmediate({
    required int    id,
    required String channelId,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _details(channelId));
  }

  static NotificationDetails _details(String channelId) => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, channelId,
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  static Future<void> _createChannel({
    required String     id,
    required String     name,
    required String     description,
    required Importance importance,
  }) async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          id, name,
          description: description,
          importance:  importance,
        ));
  }

  static tz.TZDateTime _nextTime(TimeOfDay time) {
    final now  = tz.TZDateTime.now(tz.local);
    var   next = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  static tz.TZDateTime _nextWeekday(int weekday, TimeOfDay time) {
    final now  = tz.TZDateTime.now(tz.local);
    var   next = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    while (next.weekday != weekday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static int _medId(String id)        => id.hashCode.abs();
  static int _medIdEvening(String id) => id.hashCode.abs() + 10000;
  static int _medIdStock(String id)   => id.hashCode.abs() + 20000;
  static int _apptId(String id)       => id.hashCode.abs() + 30000;
  static int _apptIdDay(String id)    => id.hashCode.abs() + 40000;

  static String _reminderLabel(int minutes) {
    if (minutes < 60)    return '$minutes minutes';
    if (minutes == 60)   return '1 hour';
    if (minutes == 1440) return '1 day';
    return '${minutes ~/ 60} hours';
  }

  static String _fmtTime(DateTime d) {
    final h   = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    final per = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$min $per';
  }

  static String _deviceTimezone() {
    try {
      return DateTime.now().timeZoneName;
    } catch (_) {
      return 'UTC';
    }
  }

  static void _onTap(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped: ${response.payload}');
  }
}