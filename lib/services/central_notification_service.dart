import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class CentralNotificationService {
  CentralNotificationService._();

  static const String _baseUrl =
      'http://192.168.31.187:5191/api';

  // =========================================================
  // GET MY NOTIFICATIONS
  // =========================================================

  static Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final token = AuthService.token;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/Notifications/my-notifications',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      return [];
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    throw Exception(
      'Failed to load notifications. '
      'Status: ${response.statusCode}',
    );
  }

  // =========================================================
  // GET UNREAD COUNT
  // =========================================================

  static Future<int> getUnreadCount() async {
    final token = AuthService.token;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/Notifications/unread-count',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map &&
          decoded['count'] != null) {
        return int.tryParse(
              decoded['count'].toString(),
            ) ??
            0;
      }

      return 0;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    throw Exception(
      'Failed to load unread notification count. '
      'Status: ${response.statusCode}',
    );
  }

  // =========================================================
  // MARK ONE AS READ
  // =========================================================

  static Future<bool> markAsRead(
    int notificationId,
  ) async {
    final token = AuthService.token;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/Notifications/$notificationId/read',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    return false;
  }

  // =========================================================
  // MARK ALL AS READ
  // =========================================================

  static Future<bool> markAllAsRead() async {
    final token = AuthService.token;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/Notifications/read-all',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    return false;
  }

  // =========================================================
  // DELETE ONE NOTIFICATION
  // =========================================================

  static Future<bool> deleteNotification(
    int notificationId,
  ) async {
    final token = AuthService.token;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/Notifications/$notificationId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    return false;
  }

  // =========================================================
  // DELETE ALL NOTIFICATIONS
  // =========================================================

  static Future<bool> deleteAllNotifications() async {
    final token = AuthService.token;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.delete(
      Uri.parse(
        '$_baseUrl/Notifications/all',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    return false;
  }
}