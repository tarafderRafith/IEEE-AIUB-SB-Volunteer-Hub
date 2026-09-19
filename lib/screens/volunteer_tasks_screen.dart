import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/task_service.dart';

class VolunteerTasksScreen extends StatefulWidget {
  const VolunteerTasksScreen({super.key});

  @override
  State<VolunteerTasksScreen> createState() =>
      _VolunteerTasksScreenState();
}

class _VolunteerTasksScreenState extends State<VolunteerTasksScreen> {
  int selectedFilter = 0;

  List<Map<String, dynamic>> tasks = [];

  bool _isLoading = true;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // ============================================================
  // LOAD TASKS FROM CENTRAL API
  // ============================================================

  Future<void> _loadTasks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loadedTasks = await TaskService.getMyTasks();

      if (!mounted) return;

      setState(() {
        tasks = loadedTasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load your tasks from the server.',
          ),
          backgroundColor: Color(0xFFB3261E),
        ),
      );
    }
  }

  // ============================================================
  // FILTERED TASKS
  // ============================================================

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedFilter == 0) {
      return tasks;
    }

    if (selectedFilter == 1) {
      return tasks
          .where(
            (task) =>
                TaskService.getStatus(task) == 'Pending',
          )
          .toList();
    }

    if (selectedFilter == 2) {
      return tasks
          .where(
            (task) =>
                TaskService.getStatus(task) == 'In Process',
          )
          .toList();
    }

    return tasks
        .where(
          (task) =>
              TaskService.getStatus(task) == 'Done',
        )
        .toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get totalPoints {
    int total = 0;

    for (final task in tasks) {
      total += TaskService.getPoints(task);
    }

    return total;
  }

  int get completedTasks {
    return tasks
        .where(
          (task) =>
              TaskService.getStatus(task) == 'Done',
        )
        .length;
  }

  int get inProcessTasks {
    return tasks
        .where(
          (task) =>
              TaskService.getStatus(task) == 'In Process',
        )
        .length;
  }

  int get pendingTasks {
    return tasks
        .where(
          (task) =>
              TaskService.getStatus(task) == 'Pending',
        )
        .length;
  }

  // ============================================================
  // COLORS
  // ============================================================

  Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFFF5C7A);

      case 'Medium':
        return const Color(0xFFFFB84D);

      default:
        return const Color(0xFF4D91FF);
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Done':
        return const Color(0xFF36D399);

      case 'In Process':
        return const Color(0xFFFFB84D);

      default:
        return const Color(0xFF4D91FF);
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'Done':
        return Icons.check_circle_rounded;

      case 'In Process':
        return Icons.autorenew_rounded;

      default:
        return Icons.schedule_rounded;
    }
  }

  // ============================================================
  // TASK ICON
  // ============================================================

  IconData taskIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('social') ||
        lowerTitle.contains('facebook') ||
        lowerTitle.contains('instagram') ||
        lowerTitle.contains('content')) {
      return Icons.campaign_rounded;
    }

    if (lowerTitle.contains('registration')) {
      return Icons.app_registration_rounded;
    }

    if (lowerTitle.contains('design') ||
        lowerTitle.contains('creative') ||
        lowerTitle.contains('poster')) {
      return Icons.palette_rounded;
    }

    if (lowerTitle.contains('web') ||
        lowerTitle.contains('website') ||
        lowerTitle.contains('development')) {
      return Icons.language_rounded;
    }

    if (lowerTitle.contains('event')) {
      return Icons.event_rounded;
    }

    if (lowerTitle.contains('research')) {
      return Icons.menu_book_rounded;
    }

    if (lowerTitle.contains('photo') ||
        lowerTitle.contains('video')) {
      return Icons.photo_library_rounded;
    }

    return Icons.task_alt_rounded;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String formatDeadline(dynamic deadline) {
    if (deadline == null ||
        deadline.toString().trim().isEmpty) {
      return 'No deadline';
    }

    try {
      final date =
          DateTime.parse(deadline.toString()).toLocal();

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
          '${date.day}, ${date.year}';
    } catch (e) {
      return deadline.toString();
    }
  }

  String formatDateTime(dynamic value) {
    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Not updated yet';
    }

    try {
      final date =
          DateTime.parse(value.toString()).toLocal();

      final hour = date.hour > 12
          ? date.hour - 12
          : date.hour == 0
              ? 12
              : date.hour;

      final minute =
          date.minute.toString().padLeft(2, '0');

      final period =
          date.hour >= 12 ? 'PM' : 'AM';

      return '${date.day}/${date.month}/${date.year} '
          '$hour:$minute $period';
    } catch (e) {
      return value.toString();
    }
  }

  // ============================================================
  // ASSIGNED BY INFORMATION
  // ============================================================

  String getAssignedByName(
    Map<String, dynamic> task,
  ) {
    final memberId =
        TaskService.getAssignedByMemberId(task);

    if (memberId.isNotEmpty) {
      return memberId;
    }

    return 'Executive';
  }

  String getAssignedByPosition(
    Map<String, dynamic> task,
  ) {
    return 'Executive Member';
  }

  String getAssignedByTeam(
    Map<String, dynamic> task,
  ) {
    final team = TaskService.getTeam(task);

    return team;
  }

  // ============================================================
  // UPDATE TASK STATUS
  // ============================================================

  Future<void> updateTaskStatus(
    Map<String, dynamic> task,
  ) async {
    if (_isUpdatingStatus) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A2145),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              20,
              24,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Update Task Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  TaskService.getTitle(task),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 25),
                _statusOption(
                  context,
                  task,
                  'Pending',
                  Icons.schedule_rounded,
                  const Color(0xFF4D91FF),
                ),
                const SizedBox(height: 12),
                _statusOption(
                  context,
                  task,
                  'In Process',
                  Icons.autorenew_rounded,
                  const Color(0xFFFFB84D),
                ),
                const SizedBox(height: 12),
                _statusOption(
                  context,
                  task,
                  'Done',
                  Icons.check_circle_rounded,
                  const Color(0xFF36D399),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusOption(
    BuildContext context,
    Map<String, dynamic> task,
    String status,
    IconData icon,
    Color color,
  ) {
    final bool selected =
        TaskService.getStatus(task) == status;

    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);

        final taskId =
            TaskService.getTaskId(task);

        if (taskId <= 0) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid task ID.',
              ),
              backgroundColor:
                  Color(0xFFB3261E),
            ),
          );
          return;
        }

        if (!mounted) return;

        setState(() {
          _isUpdatingStatus = true;
        });

        try {
  await TaskService.updateTaskStatus(
    taskId: taskId,
    status: status,
  );

  if (!mounted) return;

  await _loadTasks();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Task status updated to $status.',
      ),
      backgroundColor: const Color(0xFF0D5BD7),
    ),
  );
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Failed to update task status.',
      ),
      backgroundColor: Color(0xFFB3261E),
    ),
  );
}

        if (!mounted) return;

        setState(() {
          _isUpdatingStatus = false;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : const Color(0xFF071A36),
          borderRadius:
              BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? color
                : const Color(0xFF173D72),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 25,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041329),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF041329),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed:
                _isLoading ? null : _loadTasks,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'Refresh tasks',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: Color(0xFF3D8BFF),
                ),
              )
            : Column(
                children: [
                  _summarySection(),
                  const SizedBox(height: 22),
                  _filterSection(),
                  const SizedBox(height: 18),
                  Expanded(
                    child: filteredTasks.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            color:
                                const Color(
                              0xFF3D8BFF,
                            ),
                            backgroundColor:
                                const Color(
                              0xFF0A2145,
                            ),
                            onRefresh:
                                _loadTasks,
                            child:
                                ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
                                20,
                                0,
                                20,
                                30,
                              ),
                              itemCount:
                                  filteredTasks
                                      .length,
                              itemBuilder:
                                  (context,
                                      index) {
                                return _taskCard(
                                  filteredTasks[
                                      index],
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // SUMMARY SECTION
  // ============================================================

  Widget _summarySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        0,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D5BD7),
            Color(0xFF082E70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5BD7)
                .withOpacity(0.25),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep going!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Complete your tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tasks.length} assigned task'
                  '${tasks.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$totalPoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'POINTS',
                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.65),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER SECTION
  // ============================================================

  Widget _filterSection() {
    final filters = [
      'All',
      'Pending',
      'In Process',
      'Done',
    ];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final bool selected =
              selectedFilter == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = index;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 200),
              margin:
                  const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 19,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF0D5BD7)
                    : const Color(0xFF0A2145),
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF3E8BFF)
                      : const Color(0xFF173D72),
                ),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _taskCard(
    Map<String, dynamic> task,
  ) {
    final String status =
        TaskService.getStatus(task);

    final String priority =
        TaskService.getPriority(task);

    final String title =
        TaskService.getTitle(task);

    final String description =
        TaskService.getDescription(task);

    final String deadline =
        TaskService.getDueDate(task);

    final int points =
        TaskService.getPoints(task);

    final String assignedByName =
        getAssignedByName(task);

    final String assignedByPosition =
        getAssignedByPosition(task);

    final String assignedByTeam =
        getAssignedByTeam(task);

    final String updatedAt =
        formatDateTime(
      TaskService.getUpdatedAt(task),
    );

    final String startedAt =
        formatDateTime(
      TaskService.getStartedAt(task),
    );

    final String completedAt =
        formatDateTime(
      TaskService.getCompletedAt(task),
    );

    return Container(
      margin:
          const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF081C39),
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFF173D72),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ====================================================
          // TITLE + PRIORITY
          // ====================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF0D5BD7)
                          .withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  taskIcon(title),
                  color:
                      const Color(0xFF4D91FF),
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityColor(
                    priority,
                  ).withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color:
                        priorityColor(priority),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ====================================================
          // DESCRIPTION
          // ====================================================

          Text(
            description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 17),

          // ====================================================
          // ASSIGNED BY
          // ====================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2145),
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color:
                    const Color(0xFF173D72),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFF0D5BD7)
                            .withOpacity(0.18),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons
                        .admin_panel_settings_rounded,
                    color:
                        Color(0xFF4D91FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ASSIGNED BY',
                        style: TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        assignedByName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assignedByTeam.isEmpty
                            ? assignedByPosition
                            : '$assignedByPosition • '
                                '$assignedByTeam',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          // ====================================================
          // DEADLINE + POINTS
          // ====================================================

          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white38,
                size: 15,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  formatDeadline(deadline),
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFFC857),
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                '+$points pts',
                style: const TextStyle(
                  color:
                      Color(0xFFFFC857),
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          // ====================================================
          // TIME INFORMATION
          // ====================================================

          Container(
            padding:
                const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.black
                  .withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _timeRow(
                  Icons.update_rounded,
                  'Last Updated',
                  updatedAt,
                ),
                if (status == 'In Process' ||
                    status == 'Done')
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 8,
                    ),
                    child: _timeRow(
                      Icons
                          .play_circle_outline_rounded,
                      'Started',
                      startedAt,
                    ),
                  ),
                if (status == 'Done')
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 8,
                    ),
                    child: _timeRow(
                      Icons
                          .check_circle_outline_rounded,
                      'Completed',
                      completedAt,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          // ====================================================
          // STATUS + EDIT BUTTON
          // ====================================================

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  alignment:
                      Alignment.center,
                  decoration:
                      BoxDecoration(
                    color: statusColor(
                      status,
                    ).withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor(
                        status,
                      ).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        statusIcon(status),
                        color:
                            statusColor(status),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        status,
                        style: TextStyle(
                          color:
                              statusColor(
                            status,
                          ),
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed:
                      _isUpdatingStatus
                          ? null
                          : () =>
                              updateTaskStatus(
                                task,
                              ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF0D5BD7,
                    ),
                    disabledBackgroundColor:
                        const Color(
                      0xFF0D5BD7,
                    ).withOpacity(0.4),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIME ROW
  // ============================================================

  Widget _timeRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              const Color(0xFF4D91FF),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    String title = 'No tasks found';

    String message =
        'There are no tasks in this category right now.';

    if (tasks.isEmpty) {
      title = 'No tasks assigned yet';
      message =
          'When an Executive assigns you a task, '
          'it will appear here.';
    } else if (selectedFilter == 1) {
      title = 'No pending tasks';
      message =
          'You do not have any pending tasks right now.';
    } else if (selectedFilter == 2) {
      title = 'Nothing in process';
      message =
          'You do not have any tasks in process right now.';
    } else if (selectedFilter == 3) {
      title = 'No completed tasks';
      message =
          'Your completed tasks will appear here.';
    }

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF0D5BD7)
                        .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color:
                    Color(0xFF4D91FF),
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            if (tasks.isEmpty)
              OutlinedButton.icon(
                onPressed: _loadTasks,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'REFRESH',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF4D91FF,
                  ),
                  side:
                      const BorderSide(
                    color:
                        Color(0xFF3D8BFF),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}