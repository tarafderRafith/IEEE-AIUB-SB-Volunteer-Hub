import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Handles Firebase Cloud Messaging for the app.
///
/// FCM is responsible for receiving remote push notifications.
/// Local notifications are used to display a visible notification
/// while the application is open.
class FCMService {
FCMService._();

static final FCMService instance = FCMService._();

final FirebaseMessaging _messaging = FirebaseMessaging.instance;

StreamSubscription<RemoteMessage>? _foregroundSubscription;
StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
StreamSubscription<String>? _tokenRefreshSubscription;

/// Initializes Firebase Cloud Messaging.
Future<void> initialize() async {
try {
// Initialize the local notification system first.
await NotificationService.instance.initialize();


  // Request notification permission.
  //
  // On iOS this requests permission from the user.
  // On Android 13+ this requests notification permission.
  final settings = await _messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  debugPrint(
    'FCM permission status: ${settings.authorizationStatus}',
  );

  // Get the Firebase Cloud Messaging token.
  //
  // On iOS, an APNs token is required before Firebase can
  // provide the FCM token.
  final token = await _getTokenSafely();

  if (token != null && token.isNotEmpty) {
    debugPrint('FCM TOKEN: $token');

    // Later, when the central backend is ready,
    // this token will be sent to the backend and associated
    // with the logged-in volunteer/executive.
  }

  // Listen for messages while the app is open.
  await _foregroundSubscription?.cancel();

  _foregroundSubscription = FirebaseMessaging.onMessage.listen(
    _handleForegroundMessage,
  );

  // Listen when the user taps a notification that opened the app.
  await _messageOpenedSubscription?.cancel();

  _messageOpenedSubscription =
      FirebaseMessaging.onMessageOpenedApp.listen(
    _handleNotificationTap,
  );

  // Check whether the app was opened from a terminated state
  // by tapping an FCM notification.
  final initialMessage = await _messaging.getInitialMessage();

  if (initialMessage != null) {
    _handleNotificationTap(initialMessage);
  }

  // Listen for token refresh.
  await _tokenRefreshSubscription?.cancel();

  _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
      .listen(
    (newToken) {
      debugPrint('FCM TOKEN REFRESHED: $newToken');

      // Later we will send the new token to the backend.
    },
  );

  debugPrint('FCM service initialized successfully.');
} catch (e) {
  debugPrint('FCM initialization error: $e');
}


}

/// Safely retrieves the FCM token.
Future<String?> _getTokenSafely() async {
try {
// iOS requires an APNs token before calling getToken().
if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
final apnsToken = await _messaging.getAPNSToken();


    if (apnsToken == null || apnsToken.isEmpty) {
      debugPrint(
        'APNs token is not available yet. '
        'FCM token will be unavailable on iOS until APNs '
        'is configured.',
      );

      return null;
    }

    debugPrint('APNs token received.');
  }

  return await _messaging.getToken();
} catch (e) {
  debugPrint('Unable to get FCM token: $e');
  return null;
}


}

/// Handles an FCM message received while the app is open.
Future<void> _handleForegroundMessage(RemoteMessage message) async {
debugPrint('FCM foreground message received.');


debugPrint('Message ID: ${message.messageId}');
debugPrint('Title: ${message.notification?.title}');
debugPrint('Body: ${message.notification?.body}');
debugPrint('Data: ${message.data}');

final title = message.notification?.title ?? 'IEEE AIUB Volunteer Hub';

final body = message.notification?.body ??
    'You have a new notification from IEEE AIUB Student Branch.';

// Show a visible local notification while the app is open.
//
// Firebase notification messages do not automatically display
// a system notification when the Flutter application is in
// the foreground.
await NotificationService.instance.showNotification(
  title: title,
  body: body,
  id: _notificationId(message),
  payload: _notificationPayload(message),
);

// IMPORTANT:
//
// Your existing SQLite notification system remains separate.
// The local popup is only the visual notification layer.
//
// Later, when the central backend is implemented, remote
// notifications can also be stored in the central database.


}

/// Handles a notification when the user taps it.
void _handleNotificationTap(RemoteMessage message) {
debugPrint('FCM notification opened the app.');


debugPrint('Message ID: ${message.messageId}');
debugPrint('Data: ${message.data}');

// Later we can use message.data to navigate directly to:
//
// - a task
// - an event
// - an announcement
// - a chat
//
// Example:
//
// {
//   "type": "task_assigned",
//   "taskId": "123"
// }


}

/// Creates a stable notification ID from the FCM message.
int _notificationId(RemoteMessage message) {
final messageId = message.messageId;


if (messageId == null || messageId.isEmpty) {
  return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
}

return messageId.hashCode & 0x7fffffff;


}

/// Creates a payload for future notification navigation.
String _notificationPayload(RemoteMessage message) {
if (message.data.isEmpty) {
return '';
}


final type = message.data['type'];

if (type != null) {
  return type.toString();
}

return '';


}

/// Returns the currently available FCM token.
Future<String?> getToken() async {
return _getTokenSafely();
}

/// Stops FCM listeners.
Future<void> dispose() async {
await _foregroundSubscription?.cancel();
await _messageOpenedSubscription?.cancel();
await _tokenRefreshSubscription?.cancel();


_foregroundSubscription = null;
_messageOpenedSubscription = null;
_tokenRefreshSubscription = null;


}
}

/// Handles FCM messages when the application is running in the background.
///
/// This function MUST be top-level (not inside a class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
RemoteMessage message,
) async {
debugPrint('FCM background message received.');

debugPrint('Message ID: ${message.messageId}');
debugPrint('Title: ${message.notification?.title}');
debugPrint('Body: ${message.notification?.body}');
debugPrint('Data: ${message.data}');
}
