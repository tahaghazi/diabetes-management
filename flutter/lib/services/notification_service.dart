import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:logger/logger.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final Logger _logger = Logger();

  static Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          _logger.i('Notification response received: actionId=${response.actionId}, payload=${response.payload}');
          if (response.payload != null) {
            try {
              Map<String, dynamic> payload = jsonDecode(response.payload!);
              _logger.i('Parsed payload: $payload');

              // التحقق من حالة تسجيل الدخول
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? accessToken = prefs.getString('access_token');
              if (accessToken == null) {
                _logger.i('تم تجاهل الإشعار لأن المستخدم غير مسجل الدخول');
                return;
              }

              await logNotification(
                payload['id'],
                payload['title'],
                payload['body'],
                DateTime.parse(payload['scheduled_time']),
                reminderType: payload['reminder_type'],
                medicationName: payload['medication_name'],
              );

              if (payload['reminder_type'] == 'medication') {
                navigatorKey.currentState?.pushNamed(
                  '/medication_confirmation',
                  arguments: {
                    'notificationId': payload['id'],
                    'title': payload['title'],
                    'body': payload['body'],
                    'medicationName': payload['medication_name'],
                  },
                );
              }
            } catch (e) {
              _logger.e('Error parsing notification payload: $e');
            }
          }

          // معالجة إجراء "تم تناول الدواء"
          if (response.actionId == 'confirm_action') {
            try {
              Map<String, dynamic> payload = jsonDecode(response.payload!);
              // التحقق من حالة تسجيل الدخول
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? accessToken = prefs.getString('access_token');
              if (accessToken == null) {
                _logger.i('تم تجاهل إجراء تأكيد الدواء لأن المستخدم غير مسجل الدخول');
                return;
              }

              navigatorKey.currentState?.pushNamed(
                '/medication_confirmation',
                arguments: {
                  'notificationId': payload['id'],
                  'title': payload['title'],
                  'body': payload['body'],
                  'medicationName': payload['medication_name'],
                },
              );
            } catch (e) {
              _logger.e('Error handling confirm action: $e');
            }
          }
        },
      );

      await _createNotificationChannels();

      if (Platform.isAndroid && int.parse(Platform.version.split('.')[0]) >= 33) {
        await requestNotificationPermissions();
        await requestExactAlarmPermission();
        await requestFullScreenIntentPermission();
      }
    } catch (e) {
      _logger.e('Error initializing notifications: $e');
    }
  }

  static Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
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

    const AndroidNotificationChannel medicationAlarmChannel = AndroidNotificationChannel(
      'medication_alarm_channel',
      'منبه الأدوية',
      description: 'قناة لمنبه تناول الأدوية',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('medication'),
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: Color(0xFFF44336),
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(glucoseChannel);
    await androidPlugin?.createNotificationChannel(hydrationChannel);
    await androidPlugin?.createNotificationChannel(medicationAlarmChannel);
  }

  static Future<bool> requestNotificationPermissions() async {
    final result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final result = await androidPlugin?.requestExactAlarmsPermission();
    return result ?? false;
  }

  static Future<bool> requestFullScreenIntentPermission() async {
    // ملاحظة: flutter_local_notifications لا تدعم طلب هذا الإذن مباشرة
    // يتم الاعتماد على إذن AndroidManifest.xml
    // إذا كنت تستخدم مكتبة أخرى مثل permission_handler، يمكن طلب إذن ديناميكي هنا
    return true;
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
      // إلغاء الإشعار الموجود بنفس id إذا كان موجودًا
      await cancelNotification(id);
      _logger.i('تم إلغاء الإشعار القديم بنفس المعرف: $id');

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
            'medication_alarm_channel',
            'منبه الأدوية',
            channelDescription: 'قناة لمنبه تناول الأدوية',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('medication'),
            enableVibration: true,
            colorized: true,
            color: const Color(0xFFF44336),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            subText: medicationName,
            ongoing: false, // تعطيل ongoing للسماح بإلغاء الإشعار بعد التفاعل
            autoCancel: false, // الإبقاء على false لتجنب الإلغاء التلقائي
            fullScreenIntent: true, // تفعيل الشاشة الكاملة لكل إشعار
            timeoutAfter: null, // عدم تحديد وقت انتهاء
            ticker: 'منبه الدواء: $medicationName',
            actions: [
              const AndroidNotificationAction(
                'confirm_action',
                'تم تناول الدواء',
                showsUserInterface: true,
              ),
            ],
            additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT لتكرار الصوت
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

  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      _logger.i('تم إلغاء جميع الإشعارات');
    } catch (e) {
      _logger.e('فشل إلغاء جميع الإشعارات: $e');
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

      // تحسين التحقق من التكرار باستخدام حقول إضافية
      bool exists = loggedNotifications.any((n) {
        Map<String, dynamic> existing = jsonDecode(n);
        // تجاهل الثواني والميلي ثانية في المقارنة
        DateTime existingTime = DateTime.parse(existing['scheduled_time']);
        bool timeMatch = existingTime.year == scheduledTime.year &&
            existingTime.month == scheduledTime.month &&
            existingTime.day == scheduledTime.day &&
            existingTime.hour == scheduledTime.hour &&
            existingTime.minute == scheduledTime.minute;
        return existing['id'] == id &&
            timeMatch &&
            existing['title'] == title &&
            existing['reminder_type'] == reminderType &&
            (existing['medication_name'] ?? '') == (medicationName ?? '');
      });

      if (!exists) {
        Map<String, dynamic> notificationData = {
          'id': id,
          'title': title,
          'body': body,
          'reminder_type': reminderType,
          'scheduled_time': scheduledTime.toIso8601String(),
          'received_time': DateTime.now().toIso8601String(),
          if (medicationName != null) 'medication_name': medicationName,
        };
        loggedNotifications.add(jsonEncode(notificationData));
        await prefs.setStringList('logged_notifications', loggedNotifications);
        _logger.i('تم تسجيل الإشعار: $title');
      } else {
        _logger.i('الإشعار موجود بالفعل: $title');
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