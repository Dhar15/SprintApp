import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'storage_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId   = 'sprint_daily';
  static const _channelName = 'Daily Sprint Reminder';
  static const _notifId     = 0;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<bool> scheduleDailyNotification(TimeOfDay time) async {
    try {
        await _plugin.cancel(_notifId);

        final storage = StorageService.instance;
        await storage.setNotificationTime(time.hour, time.minute);
        await storage.setNotificationsEnabled(true);

        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
        );

        if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
        }

        const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily reminder to complete your Sprint session',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        );

        await _plugin.zonedSchedule(
        _notifId,
        _pickTitle(),
        _pickBody(),
        scheduled,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        );
        return true;
    } catch (e) {
        print('Notification scheduling failed: $e');
        await StorageService.instance.setNotificationsEnabled(false);
        return false;
    }
  }

  Future<void> cancelNotification() async {
    await _plugin.cancel(_notifId);
    await StorageService.instance.setNotificationsEnabled(false);
  }

  String _pickTitle() {
    final titles = [
      '⚡ Time to Sprint!',
      '🧠 Your daily Sprint is waiting',
      '📖 A word a day keeps dullness away',
      '🔥 Keep your streak alive!',
      '⚡ 5 minutes. That\'s all it takes.',
    ];
    titles.shuffle();
    return titles.first;
  }

  String _pickBody() {
    final bodies = [
      'Learn new words and catch up on the news.',
      'Your brain called. It wants a workout.',
      'Don\'t break the streak — open Sprint now.',
      'Today\'s words and news are ready for you.',
      'Quick session. Big gains. Let\'s go.',
    ];
    bodies.shuffle();
    return bodies.first;
  }
}