import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Delete and recreate alarm channel to ensure fullScreenIntent config
    // takes effect (Android caches channels and won't update them)
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.deleteNotificationChannel('pet_alarms');
  }

  Future<void> requestPermissions() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
    await androidImplementation?.requestFullScreenIntentPermission();

    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
            
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Checks if exact alarms can be scheduled; requests permission if not.
  /// Returns true if alarms are available.
  Future<bool> ensureAlarmPermission() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation == null) return true; // iOS or other

    final granted = await androidImplementation.requestExactAlarmsPermission();
    return granted ?? false;
  }

  // ─── Notification Details ────────────────────────────────────────────

  /// Standard notification details (silent-ish, high priority)
  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Reminders for feeding and water',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Alarm-style notification details (full-screen intent, vibration, looping sound)
  static final NotificationDetails _alarmDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'pet_alarms',
      'Pet Care Alarms',
      channelDescription: 'High-urgency alarm-style reminders',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      ongoing: true,
      autoCancel: false,
      ticker: 'Pet Care Alarm',
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    ),
  );

  // ─── Core Scheduling Methods ────────────────

  Future<void> _zonedScheduleHelper({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
    required NotificationDetails notificationDetails,
    required bool isAlarm,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final AndroidScheduleMode preferredMode = isAlarm
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.exactAllowWhileIdle;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        time,
        notificationDetails,
        androidScheduleMode: preferredMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      // Fallback to inexact if exact scheduling fails (e.g. missing exact alarm permission)
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          time,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
      } catch (fallbackError) {
        print('Error scheduling notification even with fallback: $fallbackError');
      }
    }
  }

  /// Schedule a daily repeating notification (matches time only)
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
    bool isAlarm = false,
  }) async {
    await _zonedScheduleHelper(
      id: id,
      title: title,
      body: body,
      time: time,
      notificationDetails: isAlarm ? _alarmDetails : _notificationDetails,
      isAlarm: isAlarm,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a weekly repeating notification (matches day of week + time)
  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
    bool isAlarm = false,
  }) async {
    await _zonedScheduleHelper(
      id: id,
      title: title,
      body: body,
      time: time,
      notificationDetails: isAlarm ? _alarmDetails : _notificationDetails,
      isAlarm: isAlarm,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Schedule a monthly repeating notification (matches day of month + time)
  Future<void> scheduleMonthlyReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime time,
    bool isAlarm = false,
  }) async {
    await _zonedScheduleHelper(
      id: id,
      title: title,
      body: body,
      time: time,
      notificationDetails: isAlarm ? _alarmDetails : _notificationDetails,
      isAlarm: isAlarm,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  /// Schedule a one-time notification at a specific date/time
  Future<void> scheduleFutureAlert({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isAlarm = false,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    // Don't schedule if it's in the past
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final details = isAlarm ? _alarmDetails : const NotificationDetails(
      android: AndroidNotificationDetails(
        'future_alerts',
        'Medical & Vaccine Alerts',
        channelDescription: 'Reminders for vaccines, meds, and deworming',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _zonedScheduleHelper(
      id: id,
      title: title,
      body: body,
      time: tzDate,
      notificationDetails: details,
      isAlarm: isAlarm,
    );
  }

  // ─── Convenience: Schedule from Reminder model ───────────────────────

  /// Schedules a notification/alarm from a [Reminder] object using its frequency
  Future<void> scheduleFromReminder(Reminder reminder) async {
    // Ensure exact alarm permission for alarm-type reminders
    if (reminder.isAlarm) {
      await ensureAlarmPermission();

      // If running on Android, set a system clock app alarm
      if (Platform.isAndroid) {
        List<int>? systemAlarmDays;
        if (reminder.frequency == ReminderFrequency.daily) {
          systemAlarmDays = [1, 2, 3, 4, 5, 6, 7];
        } else if (reminder.frequency == ReminderFrequency.weekly) {
          systemAlarmDays = [(reminder.dateTime.weekday % 7) + 1];
        }

        await setSystemAlarm(
          hour: reminder.dateTime.hour,
          minutes: reminder.dateTime.minute,
          message: '${reminder.petName}: ${reminder.title}',
          days: systemAlarmDays,
          skipUi: true,
        );
      }
    }


    final tzTime = tz.TZDateTime(
      tz.local,
      reminder.dateTime.year,
      reminder.dateTime.month,
      reminder.dateTime.day,
      reminder.dateTime.hour,
      reminder.dateTime.minute,
    );
    final notifId = reminder.id.hashCode.abs();
    final title = reminder.isAlarm ? '⏰ ${reminder.title}' : reminder.title;
    final body = '${reminder.petName}: ${reminder.description}';

    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        await scheduleDailyReminder(
          id: notifId,
          title: title,
          body: body,
          time: tzTime,
          isAlarm: reminder.isAlarm,
        );
        break;
      case ReminderFrequency.weekly:
        await scheduleWeeklyReminder(
          id: notifId,
          title: title,
          body: body,
          time: tzTime,
          isAlarm: reminder.isAlarm,
        );
        break;
      case ReminderFrequency.monthly:
        await scheduleMonthlyReminder(
          id: notifId,
          title: title,
          body: body,
          time: tzTime,
          isAlarm: reminder.isAlarm,
        );
        break;
      case ReminderFrequency.once:
        await scheduleFutureAlert(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: reminder.dateTime,
          isAlarm: reminder.isAlarm,
        );
        break;
    }
  }

  // ─── Water Reminders ─────────────────────────────────────────────────

  Future<void> scheduleWaterReminders({
    required int baseId,
    required String title,
    required String body,
    required int intervalHours,
  }) async {
    // Cancel existing water reminders first (assume max 12 reminders a day)
    await cancelWaterReminders(baseId);
    
    // Schedule from 8 AM to 8 PM
    int currentHour = 8;
    int offset = 0;
    
    while (currentHour <= 20) {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, currentHour);
      
      await scheduleDailyReminder(
        id: baseId + offset,
        title: title,
        body: body,
        time: scheduledDate,
      );
      
      currentHour += intervalHours;
      offset++;
    }
  }

  Future<void> cancelWaterReminders(int baseId) async {
    for (int i = 0; i < 12; i++) {
      await cancelReminder(baseId + i);
    }
  }

  /// Schedules a single daily reminder at [hour] (24h) to alert the user if
  /// water intake is incomplete. Fired from the UI only when goal is unmet.
  Future<void> scheduleWaterIncompleteReminder({
    required int id,
    required String petName,
    required int currentMl,
    required int targetMl,
    int hour = 20,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    // If the time has already passed today, skip scheduling
    if (scheduledDate.isBefore(now)) return;

    await _zonedScheduleHelper(
      id: id,
      title: '💧 Water Reminder for $petName',
      body: '$petName has only had ${currentMl}ml of water today. Target: ${targetMl}ml.',
      time: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_incomplete',
          'Water Incomplete Alerts',
          channelDescription: 'Daily evening alert if water intake is incomplete',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      isAlarm: false,
    );
  }

  Future<void> cancelReminder(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  static const MethodChannel _settingsChannel = MethodChannel('com.flutter.petcare/settings');

  /// Check if the application is ignoring battery optimizations (Android only)
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool? ignored = await _settingsChannel.invokeMethod('isBatteryOptimizationIgnored');
      return ignored ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Request the user to disable battery optimizations for the app (Android only)
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _settingsChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException catch (e) {
      print('Failed to request battery optimization settings: $e');
    }
  }

  /// Sets a native system alarm (clock app intent) for Android
  Future<bool> setSystemAlarm({
    required int hour,
    required int minutes,
    required String message,
    List<int>? days,
    bool skipUi = true,
  }) async {
    try {
      final bool? success = await _settingsChannel.invokeMethod('setSystemAlarm', {
        'hour': hour,
        'minutes': minutes,
        'message': message,
        'days': days,
        'skipUi': skipUi,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      print('Failed to set system alarm: $e');
      return false;
    }
  }
}
