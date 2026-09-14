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

  Future<void> _loadVolunteers() async {
    try {
      final volunteers =
          await DatabaseService.getVolunteers();

      if (!mounted) return;

      setState(() {
        _volunteers = volunteers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Volunteer loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Failed to load volunteers.',
        isError: true,
      );
    }
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline != null &&
                  _selectedDeadline!.isAfter(
                    DateTime(
                      now.year,
                      now.month,
                      now.day,
                    ),
                  )
              ? _selectedDeadline!
              : now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 2,
      ),
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
      _selectedDeadline = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVolunteerId == null) {
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

    final now = DateTime.now();

    final deadline = DateTime(
      _selectedDeadline!.year,
      _selectedDeadline!.month,
      _selectedDeadline!.day,
      23,
      59,
      59,
    );

    if (deadline.isBefore(now)) {
      _showMessage(
        'Deadline cannot be in the past.',
        isError: true,
      );
      return;
    }

    final points = int.tryParse(
      _pointsController.text.trim(),
    );

    if (points == null ||
        points < 0 ||
        points > 1000) {
      _showMessage(
        'Points must be between 0 and 1000.',
        isError: true,
      );
      return;
    }

    Map<String, dynamic>? selectedVolunteer;

    for (final volunteer in _volunteers) {
      final memberId =
          volunteer['member_id']?.toString().trim();

      if (memberId == _selectedVolunteerId) {
        selectedVolunteer = volunteer;
        break;
      }
    }

    if (selectedVolunteer == null) {
      _showMessage(
        'Selected volunteer could not be found.',
        isError: true,
      );
      return;
    }

    final assignedVolunteerName =
        selectedVolunteer['full_name']?.toString() ??
            'Unknown Volunteer';

    final assignedVolunteerId =
        selectedVolunteer['member_id']
                ?.toString()
                .trim() ??
            '';

    final assignedVolunteerTeam =
        selectedVolunteer['team']?.toString() ??
            'Team not assigned';

    if (assignedVolunteerId.isEmpty) {
      _showMessage(
        'Selected volunteer has no valid member ID.',
        isError: true,
      );
      return;
    }

    final title =
        _titleController.text.trim();

    final description =
        _descriptionController.text.trim();

    final assignedByMemberId =
        AuthService.memberId?.trim() ?? '';

    final assignedByName =
        AuthService.fullName ?? 'Executive';

    if (assignedByMemberId.isEmpty) {
      _showMessage(
        'Executive account information is missing. Please login again.',
        isError: true,
      );
      return;
    }

    debugPrint('');
    debugPrint(
      '========================================',
    );
    debugPrint('📋 STARTING TASK ASSIGNMENT');
    debugPrint(
      '👤 Executive: $assignedByName',
    );
    debugPrint(
      '🪪 Executive ID: $assignedByMemberId',
    );
    debugPrint(
      '👤 Volunteer: $assignedVolunteerName',
    );
    debugPrint(
      '🪪 Volunteer ID: $assignedVolunteerId',
    );
    debugPrint(
      '📋 Task: $title',
    );
    debugPrint(
      '========================================',
    );

    setState(() {
      _isAssigning = true;
    });

    try {
      // ========================================================
      // 1. CREATE TASK
      // ========================================================

      final taskId =
          await DatabaseService.createTask(
        title: title,
        description: description,
        assignedToMemberId:
            assignedVolunteerId,
        assignedByMemberId:
            assignedByMemberId,
        team: assignedVolunteerTeam,
        priority: _selectedPriority,
        deadline:
            deadline.toIso8601String(),
        points: points,
      );

      debugPrint(
        '✅ Task successfully created: $taskId',
      );

      // ========================================================
      // 2. CREATE NOTIFICATION
      // ========================================================

      final notificationId =
          await DatabaseService.createNotification(
        recipientMemberId:
            assignedVolunteerId,
        title: 'New Task Assigned',
        message:
            '$assignedByName assigned you "$title" '
            'with $points points.',
        type: 'task_assigned',
        referenceId: taskId,
      );

      debugPrint(
        '✅ Notification successfully created: '
        '$notificationId',
      );

      // ========================================================
      // 3. VERIFY NOTIFICATION
      // ========================================================

      final notifications =
          await DatabaseService
              .getNotificationsForMember(
        assignedVolunteerId,
      );

      debugPrint(
        '🔎 Verification: '
        '${notifications.length} notification(s) '
        'found for volunteer '
        '$assignedVolunteerId',
      );

      if (notifications.isNotEmpty) {
        final latest =
            notifications.first;

        debugPrint(
          '🔎 Latest notification title: '
          '${latest['title']}',
        );

        debugPrint(
          '🔎 Latest notification recipient: '
          '${latest['recipient_member_id']}',
        );
      }

      debugPrint(
        '========================================',
      );
      debugPrint(
        '🎉 TASK ASSIGNMENT COMPLETED',
      );
      debugPrint(
        '========================================',
      );
      debugPrint('');

      if (!mounted) return;

      setState(() {
        _isAssigning = false;
      });

      final shouldClose =
          await _showAssignmentConfirmation(
        volunteerName:
            assignedVolunteerName,
        memberId:
            assignedVolunteerId,
        taskTitle: title,
        priority:
            _selectedPriority,
        deadline: deadline,
        points: points,
      );

      if (!mounted) return;

      if (shouldClose) {
        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint(
        '❌ ========================================',
      );
      debugPrint(
        '❌ TASK ASSIGNMENT ERROR',
      );
      debugPrint(
        '❌ $e',
      );
      debugPrint(
        '❌ ========================================',
      );
      debugPrint(
        stackTrace.toString(),
      );

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

  Future<bool> _showAssignmentConfirmation({
    required String volunteerName,
    required String memberId,
    required String taskTitle,
    required String priority,
    required DateTime deadline,
    required int points,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF0A2348),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          titlePadding:
              const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            10,
          ),
          contentPadding:
              const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            10,
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            16,
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color:
                    Color(0xFF4D91FF),
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Task Assigned',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'The task has been successfully assigned.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildConfirmationRow(
                icon:
                    Icons.person_rounded,
                label: 'Volunteer',
                value: volunteerName,
              ),
              const SizedBox(height: 12),
              _buildConfirmationRow(
                icon:
                    Icons.badge_outlined,
                label: 'Member ID',
                value: memberId,
              ),
              const SizedBox(height: 12),
              _buildConfirmationRow(
                icon:
                    Icons.task_alt_rounded,
                label: 'Task',
                value: taskTitle,
              ),
              const SizedBox(height: 12),
              _buildConfirmationRow(
                icon:
                    Icons.flag_rounded,
                label: 'Priority',
                value: priority,
              ),
              const SizedBox(height: 12),
              _buildConfirmationRow(
                icon:
                    Icons.calendar_month_rounded,
                label: 'Deadline',
                value:
                    _formatDeadline(
                  deadline,
                ),
              ),
              const SizedBox(height: 12),
              _buildConfirmationRow(
                icon:
                    Icons.stars_rounded,
                label: 'Points',
                value:
                    '$points points',
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF0D5BD7,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildConfirmationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFF0D5BD7)
                    .withOpacity(0.16),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color:
                const Color(0xFF4D91FF),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF0D5BD7),
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatDeadline(
    DateTime date,
  ) {
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

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
          const TextStyle(
        color: Colors.white70,
      ),
      hintStyle:
          const TextStyle(
        color: Colors.white30,
      ),
      prefixIcon: Icon(
        icon,
        color:
            const Color(0xFF4D91FF),
      ),
      filled: true,
      fillColor:
          const Color(0xFF0A2348),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: Colors.white10,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: Color(0xFF3D8BFF),
          width: 1.5,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: Color(0xFFB3261E),
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide:
            const BorderSide(
          color: Color(0xFFB3261E),
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF041329),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF041329),
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
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      Color(0xFF3D8BFF),
                ),
              )
            : _volunteers.isEmpty
                ? _buildNoVolunteers()
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      10,
                      20,
                      30,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          _buildHeader(),

                          const SizedBox(
                            height: 25,
                          ),

                          _buildSectionTitle(
                            'ASSIGN TO',
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _buildVolunteerDropdown(),

                          const SizedBox(
                            height: 25,
                          ),

                          _buildSectionTitle(
                            'TASK DETAILS',
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          TextFormField(
                            controller:
                                _titleController,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                            ),
                            textCapitalization:
                                TextCapitalization
                                    .sentences,
                            decoration:
                                _inputDecoration(
                              label:
                                  'Task Title',
                              icon: Icons
                                  .task_alt_rounded,
                              hint:
                                  'e.g. Prepare event registration desk',
                            ),
                            validator:
                                (value) {
                              final text =
                                  value?.trim() ??
                                      '';

                              if (text.isEmpty) {
                                return 'Please enter a task title';
                              }

                              if (text.length <
                                  3) {
                                return 'Task title is too short';
                              }

                              if (text.length >
                                  100) {
                                return 'Task title is too long';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          TextFormField(
                            controller:
                                _descriptionController,
                            maxLines: 5,
                            minLines: 4,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              height: 1.4,
                            ),
                            textCapitalization:
                                TextCapitalization
                                    .sentences,
                            decoration:
                                _inputDecoration(
                              label:
                                  'Description',
                              icon: Icons
                                  .description_outlined,
                              hint:
                                  'Explain what the volunteer needs to do...',
                            ),
                            validator:
                                (value) {
                              final text =
                                  value?.trim() ??
                                      '';

                              if (text.isEmpty) {
                                return 'Please enter a description';
                              }

                              if (text.length <
                                  10) {
                                return 'Please provide a little more detail';
                              }

                              if (text.length >
                                  1000) {
                                return 'Description is too long';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 25,
                          ),

                          _buildSectionTitle(
                            'TASK SETTINGS',
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _buildPrioritySelector(),

                          const SizedBox(
                            height: 16,
                          ),

                          _buildDeadlinePicker(),

                          const SizedBox(
                            height: 16,
                          ),

                          TextFormField(
                            controller:
                                _pointsController,
                            keyboardType:
                                TextInputType
                                    .number,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                            ),
                            decoration:
                                _inputDecoration(
                              label:
                                  'Points',
                              icon: Icons
                                  .stars_rounded,
                              hint:
                                  'e.g. 20',
                            ),
                            validator:
                                (value) {
                              final text =
                                  value?.trim() ??
                                      '';

                              if (text.isEmpty) {
                                return 'Please enter points';
                              }

                              final points =
                                  int.tryParse(
                                text,
                              );

                              if (points ==
                                  null) {
                                return 'Enter a valid whole number';
                              }

                              if (points < 0) {
                                return 'Points cannot be negative';
                              }

                              if (points >
                                  1000) {
                                return 'Points cannot exceed 1000';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 30,
                          ),

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
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(22),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF0D5BD7),
            Color(0xFF092E70),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0D5BD7)
                    .withOpacity(0.25),
            blurRadius: 25,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.assignment_rounded,
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
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Assign work to a volunteer and track their progress.',
                  style: TextStyle(
                    color:
                        Colors.white70,
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

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        color:
            Color(0xFF6EA6FF),
        fontSize: 12,
        fontWeight:
            FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildVolunteerDropdown() {
    final validSelectedId =
        _volunteers.any(
              (volunteer) =>
                  volunteer['member_id']
                      ?.toString()
                      .trim() ==
                  _selectedVolunteerId,
            )
            ? _selectedVolunteerId
            : null;

    if (validSelectedId !=
        _selectedVolunteerId) {
      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          if (!mounted) return;

          setState(() {
            _selectedVolunteerId =
                validSelectedId;
          });
        },
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF0A2348),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value: validSelectedId,
          isExpanded: true,
          dropdownColor:
              const Color(0xFF0A2348),
          icon: const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            color:
                Color(0xFF4D91FF),
          ),
          hint: const Row(
            children: [
              Icon(
                Icons
                    .person_outline_rounded,
                color:
                    Color(0xFF4D91FF),
              ),
              SizedBox(width: 12),
              Text(
                'Select a volunteer',
                style: TextStyle(
                  color:
                      Colors.white60,
                ),
              ),
            ],
          ),
          items: _volunteers
              .map(
                (volunteer) {
                  final fullName =
                      volunteer[
                                  'full_name']
                              ?.toString() ??
                          'Unknown Volunteer';

                  final memberId =
                      volunteer[
                                  'member_id']
                              ?.toString()
                              .trim() ??
                          '';

                  final team =
                      volunteer[
                                  'team']
                              ?.toString() ??
                          'Team not assigned';

                  return DropdownMenuItem<
                      String>(
                    value: memberId,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape
                                    .circle,
                            color:
                                const Color(
                              0xFF0D5BD7,
                            ).withOpacity(
                              0.2,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .person_rounded,
                            color:
                                Color(
                              0xFF4D91FF,
                            ),
                            size: 21,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child:
                              Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                fullName,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors
                                          .white,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                '$memberId • $team',
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors
                                          .white54,
                                  fontSize:
                                      11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedVolunteerId =
                  value.trim();
            });
          },
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF0A2348),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value: _selectedPriority,
          isExpanded: true,
          dropdownColor:
              const Color(0xFF0A2348),
          icon: const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            color:
                Color(0xFF4D91FF),
          ),
          items: _priorities
              .map(
                (priority) {
                  IconData icon;

                  if (priority ==
                      'High') {
                    icon =
                        Icons
                            .priority_high_rounded;
                  } else if (priority ==
                      'Medium') {
                    icon =
                        Icons.remove_rounded;
                  } else {
                    icon =
                        Icons
                            .arrow_downward_rounded;
                  }

                  return DropdownMenuItem<
                      String>(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color:
                              const Color(
                            0xFF4D91FF,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          priority,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedPriority =
                  value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    final hasDeadline =
        _selectedDeadline != null;

    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: _selectDeadline,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFF0A2348),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: hasDeadline
                ? const Color(
                    0xFF3D8BFF,
                  ).withOpacity(0.45)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF0D5BD7,
                ).withOpacity(0.16),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Icon(
                Icons
                    .calendar_month_rounded,
                color:
                    Color(0xFF4D91FF),
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Deadline',
                    style:
                        TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    hasDeadline
                        ? _formatDeadline(
                            _selectedDeadline!,
                          )
                        : 'Select deadline',
                    style: TextStyle(
                      color: hasDeadline
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 15,
                      fontWeight: hasDeadline
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color:
                  Colors.white30,
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
            _isAssigning
                ? null
                : _assignTask,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF0D5BD7),
          disabledBackgroundColor:
              const Color(
            0xFF0D5BD7,
          ).withOpacity(0.45),
          foregroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              17,
            ),
          ),
        ),
        child: _isAssigning
            ? const SizedBox(
                width: 25,
                height: 25,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:
                      Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Icon(
                    Icons
                        .send_rounded,
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'ASSIGN TASK',
                    style:
                        TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
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
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    const Color(
                  0xFF0D5BD7,
                ).withOpacity(0.15),
              ),
              child: const Icon(
                Icons
                    .group_off_rounded,
                color:
                    Color(0xFF4D91FF),
                size: 45,
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            const Text(
              'No Volunteers Found',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Register at least one Volunteer account before assigning a task.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.white54,
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