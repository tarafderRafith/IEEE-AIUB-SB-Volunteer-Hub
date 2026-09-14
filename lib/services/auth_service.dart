import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.31.187:5191/api';

  static String? _token;
  static String? _memberId;
  static String? _fullName;
  static String? _email;
  static String? _phone;
  static String? _department;
  static String? _team;
  static String? _role;
  static String? _executivePosition;

  // ============================================================
  // GETTERS
  // ============================================================

  static String? get token => _token;

  static String? get memberId => _memberId;

  static String? get fullName => _fullName;

  static String? get email => _email;

  static String? get phone => _phone;

  static String? get department => _department;

  static String? get team => _team;

  static String? get role => _role;

  static String? get executivePosition => _executivePosition;

  static bool get isLoggedIn =>
      _token != null && _token!.isNotEmpty;

  // ============================================================
  // INITIALIZE AUTH SESSION
  // ============================================================

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('auth_token');

    _memberId = prefs.getString('member_id');

    _fullName = prefs.getString('full_name');

    _email = prefs.getString('email');

    _phone = prefs.getString('phone');

    _department = prefs.getString('department');

    _team = prefs.getString('team');

    _role = prefs.getString('role');

    _executivePosition =
        prefs.getString('executive_position');

    if (_token != null && _token!.isNotEmpty) {
      try {
        await getCurrentUser();
      } catch (_) {
        // Keep local session if the server is temporarily unavailable.
      }
    }
  }

  // ============================================================
  // REGISTER
  //
  // Keeps the OLD method signature so
  // registration_screen.dart does not need to change.
  // ============================================================

  static Future<bool> register({
    required String fullNameValue,
    required String memberIdValue,
    required String emailValue,
    required String phoneValue,
    required String departmentValue,
    required String passwordValue,
    required String roleValue,
    required String teamValue,
    String? executivePositionValue,
  }) async {
    try {
      print('========================================');
      print('REGISTER REQUEST');
      print('Member ID: ${memberIdValue.trim()}');
      print('Full Name: ${fullNameValue.trim()}');
      print('Email: ${emailValue.trim()}');
      print('Phone: ${phoneValue.trim()}');
      print('Role: $roleValue');
      print('Team: ${teamValue.trim()}');
      print('Department: ${departmentValue.trim()}');
      print(
        'Executive Position: ${executivePositionValue?.trim() ?? 'None'}',
      );
      print('API URL: $baseUrl/Auth/register');
      print('========================================');

      final response = await http
          .post(
            Uri.parse('$baseUrl/Auth/register'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'memberId': memberIdValue.trim(),
              'fullName': fullNameValue.trim(),
              'email': emailValue.trim(),
              'phone': phoneValue.trim(),
              'password': passwordValue,
              'role': roleValue,
              'team': teamValue.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('REGISTER RESPONSE STATUS: ${response.statusCode}');
      print('REGISTER RESPONSE BODY: ${response.body}');

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          'department',
          departmentValue.trim(),
        );

        await prefs.setString(
          'team',
          teamValue.trim(),
        );

        if (executivePositionValue != null &&
            executivePositionValue.trim().isNotEmpty) {
          await prefs.setString(
            'executive_position',
            executivePositionValue.trim(),
          );
        } else {
          await prefs.remove('executive_position');
        }

        _department = departmentValue.trim();

        _team = teamValue.trim();

        _executivePosition =
            executivePositionValue?.trim();

        print('REGISTER SUCCESS');
        print('========================================');

        return true;
      }

      print('REGISTER FAILED');
      print(
        'Backend message: ${data['message'] ?? 'No message returned'}',
      );
      print('HTTP status: ${response.statusCode}');
      print('========================================');

      return false;
    } catch (e) {
      print('========================================');
      print('REGISTER EXCEPTION');
      print('Exception type: ${e.runtimeType}');
      print('Exception: $e');
      print('========================================');

      return false;
    }
  }

  // ============================================================
  // LOGIN
  //
  // Keeps the OLD method signature so
  // login_screen.dart does not need to change.
  // ============================================================

  static Future<bool> login({
    required String id,
    required String enteredPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Auth/login'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'memberId': id.trim(),
              'password': enteredPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final user = data['user'];

        if (user == null || data['token'] == null) {
          return false;
        }

        await _saveSession(
          token: data['token'].toString(),
          user: Map<String, dynamic>.from(user),
        );

        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // GET CURRENT USER
  // ============================================================

  static Future<Map<String, dynamic>> getCurrentUser() async {
    if (!isLoggedIn) {
      throw Exception('You are not logged in.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/Auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      await _saveUser(
        Map<String, dynamic>.from(data),
      );

      return data;
    }

    if (response.statusCode == 401) {
      await logout();

      throw Exception(
        'Your session has expired. Please login again.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          'Could not load your profile.',
    );
  }

  // ============================================================
  // UPDATE PROFILE
  //
  // Keeps the OLD method signature so
  // edit_profile_screen.dart does not need to change.
  //
  // Department and executive position are currently stored
  // locally because the backend User model does not contain
  // those fields yet.
  // ============================================================

  static Future<bool> updateProfile({
    required String fullNameValue,
    required String emailValue,
    required String phoneValue,
    required String departmentValue,
    required String teamValue,
  }) async {
    if (!isLoggedIn) {
      return false;
    }

    try {
      // The current backend does not yet have a
      // profile-update endpoint.
      //
      // For now, save the edited profile locally.

      _fullName = fullNameValue.trim();

      _email = emailValue.trim();

      _phone = phoneValue.trim();

      _department = departmentValue.trim();

      _team = teamValue.trim();

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'full_name',
        _fullName!,
      );

      await prefs.setString(
        'email',
        _email!,
      );

      await prefs.setString(
        'phone',
        _phone!,
      );

      await prefs.setString(
        'department',
        _department!,
      );

      await prefs.setString(
        'team',
        _team!,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // UPDATE FCM TOKEN
  // ============================================================

  static Future<void> updateFcmToken(
    String fcmToken,
  ) async {
    if (!isLoggedIn) {
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/Auth/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              'token': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        await logout();
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final data = _decodeResponse(response);

        throw Exception(
          data['message']?.toString() ??
              'Could not update notification token.',
        );
      }
    } catch (_) {
      // FCM token registration should never crash the app.
    }
  }

  // ============================================================
  // CLEAR
  //
  // Kept for compatibility with existing dashboards.
  // ============================================================

  static Future<void> clear() async {
    await logout();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    _token = null;

    _memberId = null;

    _fullName = null;

    _email = null;

    _phone = null;

    _department = null;

    _team = null;

    _role = null;

    _executivePosition = null;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('auth_token');

    await prefs.remove('member_id');

    await prefs.remove('full_name');

    await prefs.remove('email');

    await prefs.remove('phone');

    await prefs.remove('department');

    await prefs.remove('team');

    await prefs.remove('role');

    await prefs.remove('executive_position');
  }

  // ============================================================
  // SAVE SESSION
  // ============================================================

  static Future<void> _saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _token = token;

    await _saveUser(user);

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'auth_token',
      token,
    );
  }

  // ============================================================
  // SAVE USER
  // ============================================================

  static Future<void> _saveUser(
    Map<String, dynamic> user,
  ) async {
    _memberId =
        user['memberId']?.toString();

    _fullName =
        user['fullName']?.toString();

    _email =
        user['email']?.toString();

    _phone =
        user['phone']?.toString();

    _role =
        user['role']?.toString();

    _team =
        user['team']?.toString();

    final prefs =
        await SharedPreferences.getInstance();

    if (_memberId != null) {
      await prefs.setString(
        'member_id',
        _memberId!,
      );
    }

    if (_fullName != null) {
      await prefs.setString(
        'full_name',
        _fullName!,
      );
    }

    if (_email != null) {
      await prefs.setString(
        'email',
        _email!,
      );
    }

    if (_phone != null) {
      await prefs.setString(
        'phone',
        _phone!,
      );
    }

    if (_role != null) {
      await prefs.setString(
        'role',
        _role!,
      );
    }

    if (_team != null) {
      await prefs.setString(
        'team',
        _team!,
      );
    } else {
      await prefs.remove('team');
    }

    // IMPORTANT:
    // Do not overwrite department/executive position here.
    // They are currently stored locally because the backend
    // User model does not contain these fields yet.

    _department =
        prefs.getString('department');

    _executivePosition =
        prefs.getString('executive_position');
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      if (response.body.isEmpty) {
        return {};
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      return {};
    }
  }
}