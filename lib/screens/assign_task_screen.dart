import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _pointsController =
      TextEditingController();

  List<Map<String, dynamic>> _volunteers = [];

  Map<String, dynamic>? _selectedVolunteer;

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

  Future<void> _loadVolunteers() async {
    final volunteers = await DatabaseService.getVolunteers();

    if (!mounted) return;

    setState(() {
      _volunteers = volunteers;
      _isLoading = false;
    });
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3D8BFF),
              surface: Color(0xFF0A2348),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDeadline = selectedDate;
    });
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVolunteer == null) {
      _showMessage(
        'Please select a volunteer.',
        isError: true,
      );
      return;
    }

    if (_selectedDeadline == null) {
      _showMessage(
        'Please select a deadline.',
        isError: true,
      );
      return;
    }

    final points = int.tryParse(
      _pointsController.text.trim(),
    );

    if (points == null || points < 0) {
      _showMessage(
        'Please enter a valid points value.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      await DatabaseService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedToMemberId:
            _selectedVolunteer!['member_id'] as String,
        assignedByMemberId:
            AuthService.memberId ?? '',
        team:
            _selectedVolunteer!['team'] as String? ??
            'Team not assigned',
        priority: _selectedPriority,
        deadline: _selectedDeadline!.toIso8601String(),
        points: points,
      );

      if (!mounted) return;

      setState(() {
        _isAssigning = false;
      });

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0A2348),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4D91FF),
                  size: 30,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Task Assigned',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'The task has been successfully assigned to the selected volunteer.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    color: Color(0xFF4D91FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAssigning = false;
      });

      _showMessage(
        'Failed to assign task. Please try again.',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF0D5BD7),
      ),
    );
  }

  String _formatDeadline(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Colors.white70,
      ),
      hintStyle: const TextStyle(
        color: Colors.white30,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF4D91FF),
      ),
      filled: true,
      fillColor: const Color(0xFF0A2348),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.white10,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF3D8BFF),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFB3261E),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFB3261E),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041329),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041329),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Assign Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3D8BFF),
                ),
              )
            : _volunteers.isEmpty
                ? _buildNoVolunteers()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      30,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),

                          const SizedBox(height: 25),

                          _buildSectionTitle('ASSIGN TO'),

                          const SizedBox(height: 10),

                          _buildVolunteerDropdown(),

                          const SizedBox(height: 25),

                          _buildSectionTitle('TASK DETAILS'),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              label: 'Task Title',
                              icon: Icons.task_alt_rounded,
                              hint:
                                  'e.g. Prepare event registration desk',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter a task title';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller:
                                _descriptionController,
                            maxLines: 5,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.4,
                            ),
                            decoration: _inputDecoration(
                              label: 'Description',
                              icon:
                                  Icons.description_outlined,
                              hint:
                                  'Explain what the volunteer needs to do...',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter a description';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 25),

                          _buildSectionTitle(
                            'TASK SETTINGS',
                          ),

                          const SizedBox(height: 10),

                          _buildPrioritySelector(),

                          const SizedBox(height: 16),

                          _buildDeadlinePicker(),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _pointsController,
                            keyboardType:
                                TextInputType.number,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: _inputDecoration(
                              label: 'Points',
                              icon: Icons.stars_rounded,
                              hint: 'e.g. 20',
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter points';
                              }

                              final points =
                                  int.tryParse(value.trim());

                              if (points == null ||
                                  points < 0) {
                                return 'Enter a valid points value';
                              }

                              return null;
                            },
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D5BD7),
            Color(0xFF092E70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0D5BD7).withOpacity(0.25),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.assignment_add,
            color: Colors.white,
            size: 38,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Assign work to a volunteer and track their progress.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF6EA6FF),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildVolunteerDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2348),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedVolunteer,
          isExpanded: true,
          dropdownColor: const Color(0xFF0A2348),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4D91FF),
          ),
          hint: const Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF4D91FF),
              ),
              SizedBox(width: 12),
              Text(
                'Select a volunteer',
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          items: _volunteers.map((volunteer) {
            final fullName =
                volunteer['full_name'] as String? ??
                    'Unknown Volunteer';

            final memberId =
                volunteer['member_id'] as String? ?? '';

            final team =
                volunteer['team'] as String? ??
                    'Team not assigned';

            return DropdownMenuItem<Map<String, dynamic>>(
              value: volunteer,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D5BD7)
                          .withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF4D91FF),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$memberId • $team',
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
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
              _selectedVolunteer = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2348),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPriority,
          isExpanded: true,
          dropdownColor: const Color(0xFF0A2348),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4D91FF),
          ),
          items: _priorities.map((priority) {
            IconData icon;

            if (priority == 'High') {
              icon = Icons.priority_high_rounded;
            } else if (priority == 'Medium') {
              icon = Icons.remove_rounded;
            } else {
              icon = Icons.arrow_downward_rounded;
            }

            return DropdownMenuItem<String>(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF4D91FF),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    priority,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedPriority = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _selectDeadline,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2348),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4D91FF),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deadline',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDeadline == null
                        ? 'Select deadline'
                        : _formatDeadline(
                            _selectedDeadline!,
                          ),
                    style: TextStyle(
                      color: _selectedDeadline == null
                          ? Colors.white54
                          : Colors.white,
                      fontSize: 15,
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
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed:
            _isAssigning ? null : _assignTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D5BD7),
          disabledBackgroundColor:
              const Color(0xFF0D5BD7)
                  .withOpacity(0.45),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _isAssigning
            ? const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
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
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'ASSIGN TASK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNoVolunteers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D5BD7)
                    .withOpacity(0.15),
              ),
              child: const Icon(
                Icons.group_off_rounded,
                color: Color(0xFF4D91FF),
                size: 45,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'No Volunteers Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Register at least one Volunteer account before assigning a task.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}