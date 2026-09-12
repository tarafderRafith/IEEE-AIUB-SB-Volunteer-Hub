import 'database_service.dart';

class AuthService {
  static String? fullName;
  static String? memberId;
  static String? email;
  static String? phone;
  static String? department;
  static String? password;
  static String? role;
  static String? team;
  static String? executivePosition;

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
    final exists = await DatabaseService.memberIdExists(memberIdValue);

    if (exists) {
      return false;
    }

    final success = await DatabaseService.registerUser(
      fullName: fullNameValue,
      memberId: memberIdValue,
      email: emailValue,
      phone: phoneValue,
      department: departmentValue,
      password: passwordValue,
      role: roleValue,
      team: teamValue,
      executivePosition: executivePositionValue,
    );

    if (success) {
      fullName = fullNameValue;
      memberId = memberIdValue;
      email = emailValue;
      phone = phoneValue;
      department = departmentValue;
      password = passwordValue;
      role = roleValue;
      team = teamValue;
      executivePosition = executivePositionValue;
    }

    return success;
  }

  static Future<bool> login({
    required String id,
    required String enteredPassword,
  }) async {
    final user = await DatabaseService.loginUser(
      memberId: id,
      password: enteredPassword,
    );

    if (user == null) {
      return false;
    }

    fullName = user['full_name'] as String?;
    memberId = user['member_id'] as String?;
    email = user['email'] as String?;
    phone = user['phone'] as String?;
    department = user['department'] as String?;
    password = user['password'] as String?;
    role = user['role'] as String?;
    team = user['team'] as String?;
    executivePosition = user['executive_position'] as String?;

    return true;
  }

  static void clear() {
    fullName = null;
    memberId = null;
    email = null;
    phone = null;
    department = null;
    password = null;
    role = null;
    team = null;
    executivePosition = null;
  }
}