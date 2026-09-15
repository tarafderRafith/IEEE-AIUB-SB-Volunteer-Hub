import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class TaskService {
  static const String _baseUrl =
      'http://192.168.31.187:5191/api';

  // ============================================================
  // GET VOLUNTEERS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getVolunteers() async {
    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/Users/volunteers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print(
          'Get volunteers failed: '
          '${response.statusCode} ${response.body}',
        );
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } catch (e) {
      print('Get volunteers error: $e');
      return [];
    }
  }

  // ============================================================
  // CREATE / ASSIGN TASK
  // ============================================================

  static Future<Map<String, dynamic>?> createTask({
    required String title,
    required String description,
    required String assignedToMemberId,
    String? team,
    String priority = 'Medium',
    int points = 0,
    DateTime? deadline,
  }) async {
    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        print('Create task failed: no authentication token.');
        return null;
      }

      final body = {
        'title': title.trim(),
        'description': description.trim(),
        'assignedToMemberId': assignedToMemberId.trim(),
        'team': team?.trim(),
        'priority': priority,
        'points': points,
        'dueDate': deadline?.toUtc().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/Tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        print(
          'Create task failed: '
          '${response.statusCode} ${response.body}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (e) {
      print('Create task error: $e');
      return null;
    }
  }

  // ============================================================
  // GET MY TASKS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getMyTasks() async {
    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/Tasks/my-tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print(
          'Get my tasks failed: '
          '${response.statusCode} ${response.body}',
        );
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } catch (e) {
      print('Get my tasks error: $e');
      return [];
    }
  }

  // ============================================================
  // GET SINGLE TASK
  // ============================================================

  static Future<Map<String, dynamic>?> getTask(int taskId) async {
    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/Tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print(
          'Get task failed: '
          '${response.statusCode} ${response.body}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (e) {
      print('Get task error: $e');
      return null;
    }
  }

  // ============================================================
  // UPDATE TASK STATUS
  // ============================================================

  static Future<Map<String, dynamic>?> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/Tasks/$taskId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        print(
          'Update task status failed: '
          '${response.statusCode} ${response.body}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (e) {
      print('Update task status error: $e');
      return null;
    }
  }

  // ============================================================
  // GET TASKS ASSIGNED BY CURRENT EXECUTIVE
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getTasksAssignedByMe() async {
    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/Tasks/assigned-by-me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print(
          'Get assigned tasks failed: '
          '${response.statusCode} ${response.body}',
        );
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } catch (e) {
      print('Get assigned tasks error: $e');
      return [];
    }
  }

  // ============================================================
  // GET ALL TASKS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/Tasks/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print(
          'Get all tasks failed: '
          '${response.statusCode} ${response.body}',
        );
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } catch (e) {
      print('Get all tasks error: $e');
      return [];
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  static int getTaskId(Map<String, dynamic> task) {
    return (task['id'] as num?)?.toInt() ?? 0;
  }

  static String getTitle(Map<String, dynamic> task) {
    return task['title']?.toString() ?? '';
  }

  static String getDescription(Map<String, dynamic> task) {
    return task['description']?.toString() ?? '';
  }

  static String getAssignedToMemberId(
    Map<String, dynamic> task,
  ) {
    return task['assignedToMemberId']?.toString() ?? '';
  }

  static String getAssignedByMemberId(
    Map<String, dynamic> task,
  ) {
    return task['assignedByMemberId']?.toString() ?? '';
  }

  static String getTeam(Map<String, dynamic> task) {
    return task['team']?.toString() ?? '';
  }

  static String getPriority(Map<String, dynamic> task) {
    return task['priority']?.toString() ?? 'Medium';
  }

  static int getPoints(Map<String, dynamic> task) {
    return (task['points'] as num?)?.toInt() ?? 0;
  }

  static String getStatus(Map<String, dynamic> task) {
    return task['status']?.toString() ?? 'Pending';
  }

  static String getDueDate(Map<String, dynamic> task) {
    return task['dueDate']?.toString() ?? '';
  }

  static String getCreatedAt(Map<String, dynamic> task) {
    return task['createdAt']?.toString() ?? '';
  }

  static String getUpdatedAt(Map<String, dynamic> task) {
    return task['updatedAt']?.toString() ?? '';
  }

  static String getStartedAt(Map<String, dynamic> task) {
    return task['startedAt']?.toString() ?? '';
  }

  static String getCompletedAt(Map<String, dynamic> task) {
    return task['completedAt']?.toString() ?? '';
  }
}