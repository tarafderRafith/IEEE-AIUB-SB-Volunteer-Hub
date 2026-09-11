import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'registration_success_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String? selectedRole;

  final fullNameController = TextEditingController();
  final memberIdController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final departmentController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final executivePositionController = TextEditingController();

  void selectRole(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  void createAccount() {
    if (selectedRole == null) {
      return;
    }

    if (fullNameController.text.trim().isEmpty ||
        memberIdController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        departmentController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
        ),
      );
      return;
    }

    if (selectedRole == 'Executive' &&
        executivePositionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your executive position.'),
        ),
      );
      return;
    }

    AuthService.register(
      fullNameValue: fullNameController.text.trim(),
      memberIdValue: memberIdController.text.trim(),
      emailValue: emailController.text.trim(),
      phoneValue: phoneController.text.trim(),
      departmentValue: departmentController.text.trim(),
      passwordValue: passwordController.text,
      roleValue: selectedRole!,
      executivePositionValue: selectedRole == 'Executive'
          ? executivePositionController.text.trim()
          : null,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationSuccessScreen(
          role: selectedRole!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    memberIdController.dispose();
    emailController.dispose();
    phoneController.dispose();
    departmentController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    executivePositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041329),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Join the IEEE AIUB Student Branch',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Choose your role',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _roleCard(
                      role: 'Volunteer',
                      icon: Icons.volunteer_activism,
                      description: 'Participate & contribute',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _roleCard(
                      role: 'Executive',
                      icon: Icons.workspace_premium,
                      description: 'Lead & manage',
                    ),
                  ),
                ],
              ),

              if (selectedRole != null) ...[
                const SizedBox(height: 35),
                _registrationForm(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required IconData icon,
    required String description,
  }) {
    final bool selected = selectedRole == role;

    return GestureDetector(
      onTap: () => selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        height: 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0D5BD7),
                    Color(0xFF082E70),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFF0A2145),
                    Color(0xFF071A36),
                  ],
                ),
          border: Border.all(
            color: selected
                ? const Color(0xFF3E8BFF)
                : const Color(0xFF163B70),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1670FF).withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 36,
              color: selected
                  ? Colors.white
                  : const Color(0xFF4D91FF),
            ),
            const Spacer(),
            Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _registrationForm() {
    final bool isExecutive = selectedRole == 'Executive';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$selectedRole Registration',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        _input(
          controller: fullNameController,
          label: 'Full Name',
          icon: Icons.person_outline,
        ),

        const SizedBox(height: 15),

        _input(
          controller: memberIdController,
          label: 'IEEE Member / Volunteer ID',
          icon: Icons.badge_outlined,
        ),

        const SizedBox(height: 15),

        _input(
          controller: emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 15),

        _input(
          controller: phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 15),

        _input(
          controller: departmentController,
          label: 'Department',
          icon: Icons.school_outlined,
        ),

        const SizedBox(height: 15),

        _input(
          controller: passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),

        const SizedBox(height: 15),

        _input(
          controller: confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_reset_outlined,
          obscureText: true,
        ),

        if (isExecutive) ...[
          const SizedBox(height: 15),

          _input(
            controller: executivePositionController,
            label: 'Executive Position',
            icon: Icons.workspace_premium_outlined,
          ),
        ],

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: createAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D5BD7),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF0D5BD7).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4D91FF),
        ),
        filled: true,
        fillColor: const Color(0xFF091F40),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF173D72),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF3E8BFF),
            width: 2,
          ),
        ),
      ),
    );
  }
}