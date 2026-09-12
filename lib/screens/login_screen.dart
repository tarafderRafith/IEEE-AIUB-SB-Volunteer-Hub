import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'registration_screen.dart';
import 'volunteer_dashboard.dart';
import 'executive_dashboard.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final _formKey = GlobalKey<FormState>();

final TextEditingController _memberIdController =
TextEditingController();

final TextEditingController _passwordController =
TextEditingController();

bool _obscurePassword = true;
bool _isLoading = false;

@override
void dispose() {
_memberIdController.dispose();
_passwordController.dispose();
super.dispose();
}

Future<void> _login() async {
if (!_formKey.currentState!.validate()) {
return;
}


setState(() {
  _isLoading = true;
});

final success = await AuthService.login(
  id: _memberIdController.text.trim(),
  enteredPassword: _passwordController.text,
);

if (!mounted) return;

setState(() {
  _isLoading = false;
});

if (!success) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Invalid Member ID or Password.',
      ),
      backgroundColor: Color(0xFFB3261E),
    ),
  );
  return;
}

final userRole = AuthService.role;

if (userRole == 'Executive') {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const ExecutiveDashboard(),
    ),
    (route) => false,
  );
} else {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const VolunteerDashboard(),
    ),
    (route) => false,
  );
}


}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFF041329),
body: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 82,
height: 82,
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: const LinearGradient(
colors: [
Color(0xFF3E8BFF),
Color(0xFF0D5BD7),
],
),
boxShadow: [
BoxShadow(
color: const Color(0xFF0D5BD7)
.withOpacity(0.4),
blurRadius: 25,
spreadRadius: 2,
),
],
),
child: const Icon(
Icons.groups_rounded,
color: Colors.white,
size: 42,
),
),
),


              const SizedBox(height: 28),

              const Center(
                child: Text(
                  'IEEE AIUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              const Center(
                child: Text(
                  'Student Branch Volunteers Hub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF4D91FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 45),

              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Login to continue to your volunteer hub.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              _buildLabel('Member ID'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _memberIdController,
                style: const TextStyle(
                  color: Colors.white,
                ),
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  hint: 'Enter your Member ID',
                  icon: Icons.badge_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your Member ID';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              _buildLabel('Password'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  color: Colors.white,
                ),
                onFieldSubmitted: (_) => _login(),
                decoration: _inputDecoration(
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white54,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5BD7),
                    disabledBackgroundColor:
                        const Color(0xFF0D5BD7).withOpacity(0.5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegistrationScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Color(0xFF4D91FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);


}

Widget _buildLabel(String text) {
return Text(
text,
style: const TextStyle(
color: Colors.white70,
fontSize: 13,
fontWeight: FontWeight.w600,
),
);
}

InputDecoration _inputDecoration({
required String hint,
required IconData icon,
}) {
return InputDecoration(
hintText: hint,
hintStyle: const TextStyle(
color: Colors.white38,
),
prefixIcon: Icon(
icon,
color: const Color(0xFF4D91FF),
),
filled: true,
fillColor: const Color(0xFF091F40),
contentPadding: const EdgeInsets.symmetric(
horizontal: 18,
vertical: 17,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: Color(0xFF173D72),
),
),
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
width: 1.5,
),
),
errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: Color(0xFFFF5C5C),
),
),
focusedErrorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(
color: Color(0xFFFF5C5C),
width: 1.5,
),
),
);
}
}
