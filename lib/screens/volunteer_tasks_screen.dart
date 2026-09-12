import 'package:flutter/material.dart';

class VolunteerTasksScreen extends StatefulWidget {
  const VolunteerTasksScreen({super.key});

  @override
  State<VolunteerTasksScreen> createState() => _VolunteerTasksScreenState();
}

class _VolunteerTasksScreenState extends State<VolunteerTasksScreen> {
  int selectedFilter = 0;

  final List<Map<String, dynamic>> tasks = [
    {
      'title': 'Promotional Campaign',
      'description': 'Promote the upcoming SPAVe 8.0 event across social media.',
      'priority': 'High',
      'status': 'Pending',
      'deadline': 'Aug 03, 2026',
      'points': 20,
      'icon': Icons.campaign_rounded,
    },
    {
      'title': 'Event Registration Desk',
      'description': 'Manage participant registration during the event.',
      'priority': 'Medium',
      'status': 'In Process',
      'deadline': 'Aug 06, 2026',
      'points': 15,
      'icon': Icons.app_registration_rounded,
    },
    {
      'title': 'Social Media Content',
      'description': 'Prepare promotional content for the branch Facebook page.',
      'priority': 'Low',
      'status': 'Done',
      'deadline': 'Jul 30, 2026',
      'points': 10,
      'icon': Icons.photo_library_rounded,
    },
  ];

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedFilter == 0) {
      return tasks;
    }

    if (selectedFilter == 1) {
      return tasks.where((task) => task['status'] == 'Pending').toList();
    }

    if (selectedFilter == 2) {
      return tasks.where((task) => task['status'] == 'In Process').toList();
    }

    return tasks.where((task) => task['status'] == 'Done').toList();
  }

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

  void updateTaskStatus(Map<String, dynamic> task) {
    String newStatus = task['status'];

    showModalBottomSheet(
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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
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
                  task['title'],
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
    final bool selected = task['status'] == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          task['status'] = status;
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task status updated to $status.'),
            backgroundColor: const Color(0xFF0D5BD7),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : const Color(0xFF071A36),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? color : const Color(0xFF173D72),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041329),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041329),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            _summarySection(),
            const SizedBox(height: 22),
            _filterSection(),
            const SizedBox(height: 18),
            Expanded(
              child: filteredTasks.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        30,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        return _taskCard(filteredTasks[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summarySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5BD7).withOpacity(0.25),
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
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep going!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Complete your tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text(
                '120',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'POINTS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final bool selected = selectedFilter == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 19,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF0D5BD7)
                    : const Color(0xFF0A2145),
                borderRadius: BorderRadius.circular(22),
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

  Widget _taskCard(Map<String, dynamic> task) {
    final String status = task['status'];
    final String priority = task['priority'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF081C39),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFF173D72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5BD7).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  task['icon'],
                  color: const Color(0xFF4D91FF),
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  task['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityColor(priority).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor(priority),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            task['description'],
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white38,
                size: 15,
              ),
              const SizedBox(width: 7),
              Text(
                task['deadline'],
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFFC857),
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                '+${task['points']} pts',
                style: const TextStyle(
                  color: Color(0xFFFFC857),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor(status).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor(status).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        status == 'Done'
                            ? Icons.check_circle_rounded
                            : status == 'In Process'
                                ? Icons.autorenew_rounded
                                : Icons.schedule_rounded,
                        color: statusColor(status),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                  onPressed: () => updateTaskStatus(task),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5BD7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: const Color(0xFF0D5BD7).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF4D91FF),
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No tasks found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no tasks in this category right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}