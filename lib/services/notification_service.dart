import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,

        // Explicitly tell iOS to present notifications
        // while the app is in the foreground.
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      const androidChannel = AndroidNotificationChannel(
        'volunteer_hub_notifications',
        'Volunteer Hub Notifications',
        description:
            'Notifications for tasks, events, announcements and other '
            'IEEE AIUB Student Branch activities.',
        importance: Importance.high,
        playSound: true,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(androidChannel);

      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      _initialized = true;

      debugPrint('Local notification service initialized successfully.');
    } catch (e) {
      debugPrint('Local notification initialization error: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'volunteer_hub_notifications',
        'Volunteer Hub Notifications',
        channelDescription:
            'Notifications for tasks, events, announcements and other '
            'IEEE AIUB Student Branch activities.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );

      debugPrint('Local notification displayed: $title');
    } catch (e) {
      debugPrint('Unable to display local notification: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped.');
    debugPrint('Payload: ${response.payload}');
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      debugPrint('Unable to cancel notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Unable to cancel all notifications: $e');
    }
  }
}