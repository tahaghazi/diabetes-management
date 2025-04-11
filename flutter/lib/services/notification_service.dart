import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:logger/logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final Logger _logger = Logger();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          if (response.payload != null) {
            try {
              Map<String, dynamic> payload = jsonDecode(response.payload!);
              await logNotification(
                payload['id'],
                payload['title'],
                payload['body'],
                DateTime.parse(payload['scheduled_time']),
                reminderType: payload['reminder_type'],
                medicationName: payload['medication_name'],
              );
            } catch (e) {
              _logger.e('Error parsing notification payload: $e');
            }
          }
        },
      );

      await _createNotificationChannels();

      if (Platform.isAndroid && int.parse(Platform.version.split('.')[0]) >= 33) {
        await requestNotificationPermissions();
      }
    } catch (e) {
      _logger.e('Error initializing notifications: $e');
    }
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel glucoseChannel = AndroidNotificationChannel(
      'glucose_channel',
      'تذكيرات الجلوكوز',
      description: 'قناة لتذكيرات فحص السكر',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('glucose'),
      enableVibration: true,
    );

    const AndroidNotificationChannel hydrationChannel = AndroidNotificationChannel(
      'hydration_channel',
      'تذكيرات الترطيب',
      description: 'قناة لتذكيرات شرب الماء',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('hydration'),
      enableVibration: true,
    );

    const AndroidNotificationChannel medicationChannel = AndroidNotificationChannel(
      'medication_channel',
      'تذكيرات الأدوية',
      description: 'قناة لتذكيرات تناول الأدوية',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('medication'),
      enableVibration: true,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(glucoseChannel);
    await androidPlugin?.createNotificationChannel(hydrationChannel);
    await androidPlugin?.createNotificationChannel(medicationChannel);
  }

  static Future<bool> requestNotificationPermissions() async {
    final result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String reminderType,
    String? medicationName,
    bool active = true,
  }) async {
    if (!active) {
      _logger.i('تم تجاهل جدولة الإشعار لأن التذكير غير نشط: $title');
      return;
    }

    try {
      final location = tz.getLocation('Africa/Cairo');
      final now = tz.TZDateTime.now(location);
      var scheduledDate = tz.TZDateTime.from(scheduledTime, location);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      AndroidNotificationDetails androidDetails;
      switch (reminderType.toLowerCase()) {
        case 'blood_glucose_test':
          androidDetails = const AndroidNotificationDetails(
            'glucose_channel',
            'تذكيرات الجلوكوز',
            channelDescription: 'قناة لتذكيرات فحص السكر',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('glucose'),
            enableVibration: true,
            colorized: true,
            color: Color(0xFF2196F3),
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          );
          break;
        case 'hydration':
          androidDetails = const AndroidNotificationDetails(
            'hydration_channel',
            'تذكيرات الترطيب',
            channelDescription: 'قناة لتذكيرات شرب الماء',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('hydration'),
            enableVibration: true,
            colorized: true,
            color: Color(0xFF4CAF50),
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          );
          break;
        case 'medication':
          androidDetails = AndroidNotificationDetails(
            'medication_channel',
            'تذكيرات الأدوية',
            channelDescription: 'قناة لتذكيرات تناول الأدوية',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('medication'),
            enableVibration: true,
            colorized: true,
            color: const Color(0xFFF44336),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            subText: medicationName,
          );
          break;
        default:
          androidDetails = const AndroidNotificationDetails(
            'glucose_channel',
            'تذكيرات الجلوكوز',
            channelDescription: 'قناة لتذكيرات فحص السكر',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('glucose'),
            enableVibration: true,
            colorized: true,
            color: Color(0xFF2196F3),
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          );
      }

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final payload = jsonEncode({
        'id': id,
        'title': title,
        'body': body,
        'reminder_type': reminderType,
        'scheduled_time': scheduledTime.toIso8601String(),
        if (medicationName != null) 'medication_name': medicationName,
      });

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      _logger.i('تم جدولة الإشعار بنجاح: $title ($reminderType) في $scheduledDate');
    } catch (e) {
      _logger.e('فشل جدولة الإشعار: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      _logger.i('تم إلغاء الإشعار رقم $id');
    } catch (e) {
      _logger.e('فشل إلغاء الإشعار: $e');
    }
  }

  static Future<void> logNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime, {
    required String reminderType,
    String? medicationName,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> loggedNotifications = prefs.getStringList('logged_notifications') ?? [];

      Map<String, dynamic> notificationData = {
        'id': id,
        'title': title,
        'body': body,
        'reminder_type': reminderType,
        'scheduled_time': scheduledTime.toIso8601String(),
        'received_time': DateTime.now().toIso8601String(),
        if (medicationName != null) 'medication_name': medicationName,
      };

      bool exists = loggedNotifications.any((n) {
        Map<String, dynamic> existing = jsonDecode(n);
        return existing['id'] == id && existing['scheduled_time'] == scheduledTime.toIso8601String();
      });

      if (!exists) {
        loggedNotifications.add(jsonEncode(notificationData));
        await prefs.setStringList('logged_notifications', loggedNotifications);
        _logger.i('تم تسجيل الإشعار: $title');
      }
    } catch (e) {
      _logger.e('فشل تسجيل الإشعار: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLoggedNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> loggedNotifications = prefs.getStringList('logged_notifications') ?? [];
      return loggedNotifications
          .map((notification) => jsonDecode(notification) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('فشل جلب الإشعارات المسجلة: $e');
      return [];
    }
  }

  static Future<void> clearLoggedNotifications() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_notifications');
      _logger.i('تم مسح جميع الإشعارات المسجلة');
    } catch (e) {
      _logger.e('فشل مسح الإشعارات المسجلة: $e');
    }
  }
}