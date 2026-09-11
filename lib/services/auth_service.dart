class AuthService {
  static String? fullName;
  static String? memberId;
  static String? email;
  static String? phone;
  static String? department;
  static String? password;
  static String? role;
  static String? executivePosition;

  static bool register({
    required String fullNameValue,
    required String memberIdValue,
    required String emailValue,
    required String phoneValue,
    required String departmentValue,
    required String passwordValue,
    required String roleValue,
    String? executivePositionValue,
  }) {
    fullName = fullNameValue;
    memberId = memberIdValue;
    email = emailValue;
    phone = phoneValue;
    department = departmentValue;
    password = passwordValue;
    role = roleValue;
    executivePosition = executivePositionValue;

    return true;
  }

  static bool login({
    required String id,
    required String enteredPassword,
  }) {
    return memberId == id && password == enteredPassword;
  }

  static void clear() {
    fullName = null;
    memberId = null;
    email = null;
    phone = null;
    department = null;
    password = null;
    role = null;
    executivePosition = null;
  }
}