import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _departmentController;
  late final TextEditingController _teamController;

  bool _isSaving = false;

  static const Color _backgroundColor = Color(0xFF06152E);
  static const Color _cardColor = Color(0xFF0B2244);
  static const Color _borderColor = Color(0xFF153A69);
  static const Color _primaryBlue = Color(0xFF2388FF);
  static const Color _lightBlue = Color(0xFF5EA9FF);

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(
      text: AuthService.fullName ?? '',
    );

    _emailController = TextEditingController(
      text: AuthService.email ?? '',
    );

    _phoneController = TextEditingController(
      text: AuthService.phone ?? '',
    );

    _departmentController = TextEditingController(
      text: AuthService.department ?? '',
    );

    _teamController = TextEditingController(
      text: AuthService.team ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _teamController.dispose();

    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await AuthService.updateProfile(
        fullNameValue: _fullNameController.text.trim(),
        emailValue: _emailController.text.trim(),
        phoneValue: _phoneController.text.trim(),
        departmentValue: _departmentController.text.trim(),
        teamValue: _teamController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile updated successfully.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF168A61),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        setState(() {
          _isSaving = false;
        });

        _showError('Unable to update profile. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ Edit profile error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFB9364F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }

    final phone = value.trim();

    if (phone.length < 7) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              35,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 22),
                _buildEditableSection(),
                const SizedBox(height: 20),
                _buildLockedSection(),
                const SizedBox(height: 26),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _fullNameController.text.trim();

    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : 'V';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D3B78),
            Color(0xFF092850),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF1B5CA8),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.10),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0D6EFD),
                  Color(0xFF174EA6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF62AFFF),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update your profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Keep your contact and membership information up to date.',
                  style: TextStyle(
                    color: Color(0xFF9DB9D7),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Column(
            children: [
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  return _requiredValidator(
                    value,
                    'Full name',
                  );
                },
              ),
              const SizedBox(height: 13),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 13),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),
              const SizedBox(height: 13),
              _buildTextField(
                controller: _departmentController,
                label: 'Department',
                hint: 'Enter your department',
                icon: Icons.school_outlined,
                validator: (value) {
                  return _requiredValidator(
                    value,
                    'Department',
                  );
                },
              ),
              const SizedBox(height: 13),
              _buildTextField(
                controller: _teamController,
                label: 'Team',
                hint: 'Enter your team',
                icon: Icons.groups_outlined,
                validator: (value) {
                  return _requiredValidator(
                    value,
                    'Team',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedSection() {
    final executivePosition =
        AuthService.executivePosition?.trim() ?? '';

    final hasExecutivePosition =
        executivePosition.isNotEmpty &&
        executivePosition.toLowerCase() != 'null';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membership Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'These details cannot be changed from your profile.',
          style: TextStyle(
            color: Color(0xFF718CA9),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: _borderColor,
            ),
          ),
          child: Column(
            children: [
              _buildLockedField(
                label: 'Member ID',
                value: AuthService.memberId ?? 'N/A',
                icon: Icons.badge_outlined,
              ),
              _buildDivider(),
              _buildLockedField(
                label: 'Role',
                value: AuthService.role ?? 'Volunteer',
                icon: Icons.person_outline_rounded,
              ),
              if (hasExecutivePosition) ...[
                _buildDivider(),
                _buildLockedField(
                  label: 'Executive Position',
                  value: executivePosition,
                  icon: Icons.workspace_premium_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: _lightBlue,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFF7895B7),
          fontSize: 11,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF4E6B8C),
          fontSize: 11,
        ),
        prefixIcon: Icon(
          icon,
          color: _lightBlue,
          size: 19,
        ),
        filled: true,
        fillColor: const Color(0xFF081C39),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF153A69),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF153A69),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2388FF),
            width: 1.3,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD95B70),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD95B70),
            width: 1.3,
          ),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF8296),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: const Color(0xFF2388FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5A7EA6),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF627F9F),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9EB8D2),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF4D6B8D),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: _borderColor,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          disabledBackgroundColor: const Color(0xFF17477F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_rounded,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}