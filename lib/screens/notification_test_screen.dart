import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String _permissionStatus = 'Checking...';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final permissions = await iosPlugin?.checkPermissions();

      if (!mounted) {
        return;
      }

      setState(() {
        if (permissions == null) {
          _permissionStatus = 'Unable to check permission';
        } else {
          _permissionStatus =
              'Alert: ${permissions.isEnabled}\n'
              'Badge: ${permissions.isBadgeEnabled}\n'
              'Sound: ${permissions.isSoundEnabled}';
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _permissionStatus = 'Error: $e';
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('iOS local notification permission result: $result');

      await _checkPermission();
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    await NotificationService.instance.showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: 'IEEE AIUB Volunteer Hub',
      body: '🔔 Local notification test!',
      payload: 'test_notification',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06152E),
      appBar: AppBar(
        title: const Text('Notification Test'),
        backgroundColor: const Color(0xFF0A3D91),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'iOS Notification Test',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3D91),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _permissionStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _requestPermission,
                  child: const Text(
                    'Request Notification Permission',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _sendTestNotification,
                  child: const Text(
                    'Send Test Notification',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _checkPermission,
                  child: const Text(
                    'Check Permission Again',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}