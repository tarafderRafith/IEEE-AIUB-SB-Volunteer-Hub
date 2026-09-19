import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/task_service.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _pointsController =
      TextEditingController(text: '10');

  List<Map<String, dynamic>> _volunteers = [];

  String? _selectedVolunteerId;

  String _selectedPriority = 'Medium';

  DateTime? _selectedDeadline;

  bool _isLoading = true;

  bool _isAssigning = false;

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
  ];

  @override
  void initState() {
    super.initState();
    _loadVolunteers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD VOLUNTEERS FROM BACKEND
  // ============================================================

  Future<void> _loadVolunteers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final volunteers = await TaskService.getVolunteers();

      if (!mounted) {
        return;
      }

      setState(() {
        _volunteers = volunteers;

        if (_volunteers.isEmpty) {
          _selectedVolunteerId = null;
        } else {
          final selectedStillExists = _volunteers.any(
            (volunteer) =>
                volunteer['memberId']?.toString() ==
                _selectedVolunteerId,
          );

          if (!selectedStillExists) {
            _selectedVolunteerId = null;
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _volunteers = [];
        _selectedVolunteerId = null;
        _isLoading = false;
      });

      _showMessage(
        'Could not load volunteers from the server.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SELECT DEADLINE
  // ============================================================

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final initialDate =
        _selectedDeadline ?? now.add(const Duration(days: 1));

    final firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final lastDate = DateTime(
      now.year + 5,
      now.month,
      now.day,
    );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isBefore(firstDate)
              ? firstDate
              : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2F80ED),
              surface: Color(0xFF0B2142),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime:
          _selectedDeadline != null
              ? TimeOfDay.fromDateTime(_selectedDeadline!)
              : const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2F80ED),
              surface: Color(0xFF0B2142),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDeadline = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  // ============================================================
  // ASSIGN TASK
  // ============================================================

  Future<void> _assignTask() async {
    final title = _titleController.text.trim();

    final description =
        _descriptionController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Please enter a task title.',
        isError: true,
      );
      return;
    }

    if (description.isEmpty) {
      _showMessage(
        'Please enter a task description.',
        isError: true,
      );
      return;
    }

    if (_selectedVolunteerId == null ||
        _selectedVolunteerId!.isEmpty) {
      _showMessage(
        'Please select a volunteer.',
        isError: true,
      );
      return;
    }

    final points =
        int.tryParse(_pointsController.text.trim());

    if (points == null) {
      _showMessage(
        'Please enter a valid points value.',
        isError: true,
      );
      return;
    }

    if (points < 0 || points > 1000) {
      _showMessage(
        'Points must be between 0 and 1000.',
        isError: true,
      );
      return;
    }

    final selectedVolunteer =
        _volunteers.firstWhere(
      (volunteer) =>
          volunteer['memberId']?.toString() ==
          _selectedVolunteerId,
      orElse: () => <String, dynamic>{},
    );

    if (selectedVolunteer.isEmpty) {
      _showMessage(
        'Selected volunteer could not be found.',
        isError: true,
      );
      return;
    }

    final volunteerName =
        selectedVolunteer['fullName']?.toString() ??
            'Unknown Volunteer';

    final volunteerMemberId =
        selectedVolunteer['memberId']?.toString() ??
            '';

    final volunteerTeam =
        selectedVolunteer['team']?.toString();

    final executiveName =
        AuthService.fullName ?? 'Executive';

    if (volunteerMemberId.isEmpty) {
      _showMessage(
        'Volunteer member ID is missing.',
        isError: true,
      );
      return;
    }

    final confirmed =
        await _showConfirmationDialog(
      volunteerName: volunteerName,
      volunteerMemberId: volunteerMemberId,
      volunteerTeam: volunteerTeam,
      title: title,
      priority: _selectedPriority,
      deadline: _selectedDeadline,
      points: points,
      executiveName: executiveName,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final result = await TaskService.createTask(
        title: title,
        description: description,
        assignedToMemberId: volunteerMemberId,
        team: volunteerTeam,
        priority: _selectedPriority,
        points: points,
        deadline: _selectedDeadline,
      );

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _isAssigning = false;
        });

        _showMessage(
          'Task could not be assigned. Please check your connection and try again.',
          isError: true,
        );

        return;
      }

      setState(() {
        _isAssigning = false;
      });

      await _showSuccessDialog(
        volunteerName: volunteerName,
        taskTitle: title,
        priority: _selectedPriority,
        deadline: _selectedDeadline,
        points: points,
      );

      if (!mounted) {
        return;
      }

      _titleController.clear();
      _descriptionController.clear();
      _pointsController.text = '10';

      setState(() {
        _selectedVolunteerId = null;
        _selectedPriority = 'Medium';
        _selectedDeadline = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAssigning = false;
      });

      _showMessage(
        'Something went wrong while assigning the task.',
        isError: true,
      );
    }
  }

  // ============================================================
  // CONFIRMATION DIALOG
  // ============================================================

  Future<bool?> _showConfirmationDialog({
    required String volunteerName,
    required String volunteerMemberId,
    required String? volunteerTeam,
    required String title,
    required String priority,
    required DateTime? deadline,
    required int points,
    required String executiveName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B2142),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: Color(0xFF4DA3FF),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildConfirmationRow(
                  'Volunteer',
                  volunteerName,
                ),
                _buildConfirmationRow(
                  'Member ID',
                  volunteerMemberId,
                ),
                _buildConfirmationRow(
                  'Team',
                  volunteerTeam?.isNotEmpty == true
                      ? volunteerTeam!
                      : 'Not assigned',
                ),
                _buildConfirmationRow(
                  'Task',
                  title,
                ),
                _buildConfirmationRow(
                  'Priority',
                  priority,
                ),
                _buildConfirmationRow(
                  'Deadline',
                  _formatDeadline(deadline),
                ),
                _buildConfirmationRow(
                  'Points',
                  points.toString(),
                ),
                _buildConfirmationRow(
                  'Assigned by',
                  executiveName,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1769E0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Assign Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog({
    required String volunteerName,
    required String taskTitle,
    required String priority,
    required DateTime? deadline,
    required int points,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B2142),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Task Assigned!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$taskTitle has been assigned to $volunteerName.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF06152E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow(
                      'Priority',
                      priority,
                    ),
                    _buildConfirmationRow(
                      'Deadline',
                      _formatDeadline(deadline),
                    ),
                    _buildConfirmationRow(
                      'Points',
                      points.toString(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1769E0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor:
              isError
                  ? const Color(0xFFB42318)
                  : const Color(0xFF16794A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // FORMAT DEADLINE
  // ============================================================

  String _formatDeadline(DateTime? dateTime) {
    if (dateTime == null) {
      return 'No deadline';
    }

    final day =
        dateTime.day.toString().padLeft(2, '0');

    final month =
        dateTime.month.toString().padLeft(2, '0');

    final year =
        dateTime.year.toString();

    final hour =
        dateTime.hour.toString().padLeft(2, '0');

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  // ============================================================
  // CONFIRMATION ROW
  // ============================================================

  Widget _buildConfirmationRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

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
        color: Colors.white54,
      ),
      filled: true,
      fillColor: const Color(0xFF0A1E3A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.white10,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2F80ED),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C3A82),
            Color(0xFF0A2859),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment_add,
              color: Color(0xFF63B3FF),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Assign work to a volunteer and track progress.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
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

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4DA3FF),
          size: 19,
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VOLUNTEER DROPDOWN
  // ============================================================

  Widget _buildVolunteerDropdown() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1E3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4DA3FF),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading volunteers...',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    if (_volunteers.isEmpty) {
      return _buildNoVolunteers();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1E3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedVolunteerId,
        isExpanded: true,
        dropdownColor: const Color(0xFF0B2142),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white54,
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: Colors.white54,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
        ),
        hint: const Text(
          'Select a volunteer',
          style: TextStyle(
            color: Colors.white38,
          ),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        items: _volunteers.map((volunteer) {
          final memberId =
              volunteer['memberId']?.toString() ?? '';

          final fullName =
              volunteer['fullName']?.toString() ??
                  'Unknown Volunteer';

          final team =
              volunteer['team']?.toString();

          return DropdownMenuItem<String>(
            value: memberId,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1769E0)
                        .withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF4DA3FF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        team != null &&
                                team.isNotEmpty
                            ? '$memberId • $team'
                            : memberId,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedVolunteerId = value;
          });
        },
      ),
    );
  }

  // ============================================================
  // PRIORITY SELECTOR
  // ============================================================

  Widget _buildPrioritySelector() {
    return Row(
      children: _priorities.map((priority) {
        final selected =
            _selectedPriority == priority;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right:
                  priority == _priorities.last
                      ? 0
                      : 8,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPriority = priority;
                });
              },
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color(0xFF1769E0)
                          : const Color(0xFF0A1E3A),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selected
                            ? const Color(0xFF4DA3FF)
                            : Colors.white10,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      priority == 'High'
                          ? Icons.priority_high_rounded
                          : priority == 'Medium'
                              ? Icons.remove_rounded
                              : Icons.keyboard_arrow_down_rounded,
                      color:
                          selected
                              ? Colors.white
                              : Colors.white54,
                      size: 19,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      priority,
                      style: TextStyle(
                        color:
                            selected
                                ? Colors.white
                                : Colors.white60,
                        fontSize: 11,
                        fontWeight:
                            selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // DEADLINE PICKER
  // ============================================================

  Widget _buildDeadlinePicker() {
    return GestureDetector(
      onTap: _selectDeadline,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1E3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4DA3FF),
              size: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deadline',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDeadline == null
                        ? 'Select deadline'
                        : _formatDeadline(
                            _selectedDeadline,
                          ),
                    style: TextStyle(
                      color:
                          _selectedDeadline == null
                              ? Colors.white38
                              : Colors.white,
                      fontSize: 13,
                      fontWeight:
                          _selectedDeadline == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white30,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ASSIGN BUTTON
  // ============================================================

  Widget _buildAssignButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed:
            _isAssigning
                ? null
                : _assignTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1769E0),
          disabledBackgroundColor:
              const Color(0xFF1769E0)
                  .withOpacity(0.45),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child:
            _isAssigning
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Assign Task',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // ============================================================
  // NO VOLUNTEERS
  // ============================================================

  Widget _buildNoVolunteers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1E3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            color: Colors.white30,
            size: 38,
          ),
          const SizedBox(height: 10),
          const Text(
            'No Volunteers Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'There are no active volunteer accounts available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loadVolunteers,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFF4DA3FF),
              side: const BorderSide(
                color: Color(0xFF1769E0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06152E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06152E),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Assign Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF4DA3FF),
          backgroundColor: const Color(0xFF0B2142),
          onRefresh: _loadVolunteers,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              32,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 28),

                _buildSectionTitle(
                  'ASSIGN TO',
                  Icons.people_alt_outlined,
                ),

                const SizedBox(height: 11),

                _buildVolunteerDropdown(),

                const SizedBox(height: 28),

                _buildSectionTitle(
                  'TASK DETAILS',
                  Icons.description_outlined,
                ),

                const SizedBox(height: 11),

                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  textInputAction:
                      TextInputAction.next,
                  decoration: _inputDecoration(
                    hint: 'Task title',
                    icon: Icons.title_rounded,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller:
                      _descriptionController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  minLines: 4,
                  maxLines: 7,
                  textInputAction:
                      TextInputAction.newline,
                  decoration: _inputDecoration(
                    hint: 'Describe what needs to be done...',
                    icon:
                        Icons.notes_rounded,
                  ),
                ),

                const SizedBox(height: 28),

                _buildSectionTitle(
                  'TASK SETTINGS',
                  Icons.tune_rounded,
                ),

                const SizedBox(height: 11),

                const Text(
                  'Priority',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                _buildPrioritySelector(),

                const SizedBox(height: 16),

                _buildDeadlinePicker(),

                const SizedBox(height: 12),

                TextField(
                  controller: _pointsController,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  keyboardType:
                      TextInputType.number,
                  decoration: _inputDecoration(
                    hint: 'Points (0 - 1000)',
                    icon:
                        Icons.stars_rounded,
                  ),
                ),

                const SizedBox(height: 30),

                _buildAssignButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}