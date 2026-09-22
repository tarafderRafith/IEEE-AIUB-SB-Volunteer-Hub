import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/task_service.dart';
import 'event_details_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'volunteer_events_screen.dart';
import 'volunteer_tasks_screen.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() =>
      _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _events = [];

  bool _isLoadingTasks = true;
  bool _isLoadingEvents = true;

  int _unreadNotificationCount = 0;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadDashboardData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (mounted) {
          _loadDashboardData();
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // NOTIFICATION COUNT
  // ============================================================

  Future<void> _loadUnreadNotificationCount() async {
    final memberId = AuthService.memberId?.trim();

    if (memberId == null || memberId.isEmpty) {
      return;
    }

    try {
      final count =
          await DatabaseService.getUnreadNotificationCount(memberId);

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (e) {
      debugPrint('❌ Failed to load notification count: $e');
    }
  }

  // ============================================================
  // OPEN NOTIFICATIONS
  // ============================================================

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );

    await _loadUnreadNotificationCount();
  }

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    await _loadDashboardData();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadTasks(),
      _loadEvents(),
      _loadUnreadNotificationCount(),
    ]);
  }

  // ============================================================
  // LOAD TASKS FROM CENTRAL API
  // ============================================================

  Future<void> _loadTasks() async {
    try {
      final loadedTasks = await TaskService.getMyTasks();

      if (!mounted) return;

      setState(() {
        _tasks = loadedTasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      debugPrint(
        '❌ Failed to load volunteer tasks from API: $e',
      );

      if (!mounted) return;

      setState(() {
        _tasks = [];
        _isLoadingTasks = false;
      });
    }
  }

  // ============================================================
  // LOAD EVENTS
  // ============================================================

  Future<void> _loadEvents() async {
    try {
      final events = await DatabaseService.getAllEvents();

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load events: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  // ============================================================
  // TASK SUMMARY
  // ============================================================

  int get totalTaskCount {
    return _tasks.length;
  }

  int get pendingTaskCount {
    return _tasks.where((task) {
      return TaskService.getStatus(task) == 'Pending';
    }).length;
  }

  int get inProcessTaskCount {
    return _tasks.where((task) {
      return TaskService.getStatus(task) == 'In Process';
    }).length;
  }

  int get completedTaskCount {
    return _tasks.where((task) {
      return TaskService.getStatus(task) == 'Done';
    }).length;
  }

  double get completionPercentage {
    if (_tasks.isEmpty) {
      return 0;
    }

    return completedTaskCount / _tasks.length;
  }

  int get completedPoints {
    int total = 0;

    for (final task in _tasks) {
      if (TaskService.getStatus(task) != 'Done') {
        continue;
      }

      total += TaskService.getPoints(task);
    }

    return total;
  }

  List<Map<String, dynamic>> get latestTasks {
    if (_tasks.length <= 3) {
      return _tasks;
    }

    return _tasks.take(3).toList();
  }

  // ============================================================
  // EVENT DATE/TIME
  // ============================================================

  DateTime? _getEventDateTime(
    Map<String, dynamic> event,
  ) {
    final dateValue = event['date']?.toString().trim() ?? '';
    final timeValue = event['time']?.toString().trim() ?? '';

    if (dateValue.isEmpty) {
      return null;
    }

    try {
      if (timeValue.isNotEmpty) {
        final combined = '$dateValue $timeValue';

        final parsed = DateTime.tryParse(combined);

        if (parsed != null) {
          return parsed;
        }

        final parsedDate = DateTime.tryParse(dateValue);

        if (parsedDate != null) {
          final timeMatch = RegExp(
            r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
            caseSensitive: false,
          ).firstMatch(timeValue);

          if (timeMatch != null) {
            int hour = int.parse(timeMatch.group(1)!);
            final minute = int.parse(timeMatch.group(2)!);
            final meridiem =
                timeMatch.group(3)?.toUpperCase();

            if (meridiem == 'PM' && hour < 12) {
              hour += 12;
            }

            if (meridiem == 'AM' && hour == 12) {
              hour = 0;
            }

            return DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
              hour,
              minute,
            );
          }
        }
      }

      final parsedDate = DateTime.tryParse(dateValue);

      if (parsedDate != null) {
        return parsedDate;
      }
    } catch (e) {
      debugPrint(
        '❌ Event date parsing error: $e',
      );
    }

    return null;
  }

  Map<String, dynamic>? get upcomingEvent {
    if (_events.isEmpty) {
      return null;
    }

    final now = DateTime.now();

    final futureEvents = _events.where((event) {
      final eventDateTime =
          _getEventDateTime(event);

      if (eventDateTime == null) {
        return false;
      }

      return eventDateTime.isAfter(now);
    }).toList();

    if (futureEvents.isEmpty) {
      return null;
    }

    futureEvents.sort((a, b) {
      final dateA =
          _getEventDateTime(a);
      final dateB =
          _getEventDateTime(b);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateA.compareTo(dateB);
    });

    return futureEvents.first;
  }

  String _formatEventDate(
    Map<String, dynamic> event,
  ) {
    final dateTime =
        _getEventDateTime(event);

    if (dateTime == null) {
      final value =
          event['date']?.toString();

      return value == null || value.isEmpty
          ? 'Date not available'
          : value;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[dateTime.month - 1]} '
        '${dateTime.day}, '
        '${dateTime.year}';
  }

  String _formatEventTime(
    Map<String, dynamic> event,
  ) {
    final time =
        event['time']?.toString().trim();

    if (time == null || time.isEmpty) {
      return 'Time not available';
    }

    return time;
  }

  // ============================================================
  // TASK DEADLINE
  // ============================================================

  String _formatTaskDeadline(
    Map<String, dynamic> task,
  ) {
    final deadline =
        TaskService.getDueDate(task).trim();

    if (deadline.isEmpty) {
      return 'No deadline';
    }

    final parsed =
        DateTime.tryParse(deadline);

    if (parsed == null) {
      return deadline;
    }

    final localDate = parsed.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[localDate.month - 1]} '
        '${localDate.day}, '
        '${localDate.year}';
  }

  // ============================================================
  // TASK STATUS
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'Done':
        return const Color(0xFF36D399);

      case 'In Process':
        return const Color(0xFF38BDF8);

      case 'Pending':
      default:
        return const Color(0xFFFBBF24);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Done':
        return 'Completed';

      case 'In Process':
        return 'In Process';

      case 'Pending':
      default:
        return 'Pending';
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    AuthService.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final name =
        AuthService.fullName?.trim().isNotEmpty == true
            ? AuthService.fullName!.trim()
            : 'Volunteer';

    return Scaffold(
      backgroundColor: const Color(0xFF06152E),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2388FF),
          backgroundColor:
              const Color(0xFF0B2244),
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              35,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(name),
                const SizedBox(height: 24),
                _buildWelcome(name),
                const SizedBox(height: 20),
                _buildUpcomingEvent(),
                const SizedBox(height: 20),
                _buildProgressCard(),
                const SizedBox(height: 22),
                _buildLatestTasks(),
                const SizedBox(height: 22),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(String name) {
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : 'V';

    return Row(
      children: [
        GestureDetector(
          onTap: _openProfile,
          child: Container(
            width: 50,
            height: 50,
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
                color:
                    const Color(0xFF4F9CFF),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFF0D6EFD)
                          .withOpacity(0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _openProfile,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Color(0xFF7895B7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color:
                    const Color(0xFF0B2244),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      const Color(0xFF153A69),
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed:
                    _openNotifications,
                icon: const Icon(
                  Icons
                      .notifications_none_rounded,
                  color:
                      Color(0xFFBBD8F7),
                  size: 22,
                ),
              ),
            ),
            if (_unreadNotificationCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  constraints:
                      const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFF4D67),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          const Color(0xFF06152E),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _unreadNotificationCount >
                              99
                          ? '99+'
                          : _unreadNotificationCount
                              .toString(),
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color:
                const Color(0xFF0B2244),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color:
                  const Color(0xFF153A69),
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color:
                  Color(0xFF9BB5D1),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(22),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF0D3B78),
            Color(0xFF092850),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color:
              const Color(0xFF164D88),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0D6EFD)
                    .withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volunteer Dashboard',
                  style: TextStyle(
                    color:
                        Color(0xFF6EB3FF),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Keep up the great work, $name!',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Stay on top of your assigned tasks and events.',
                  style: TextStyle(
                    color:
                        Color(0xFF9DB8D7),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 53,
            height: 53,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF0D6EFD)
                      .withOpacity(0.13),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color:
                    const Color(0xFF318DFF)
                        .withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons
                  .volunteer_activism_rounded,
              color:
                  Color(0xFF5DA7FF),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPCOMING EVENT
  // ============================================================

  Widget _buildUpcomingEvent() {
    final event = upcomingEvent;

    if (_isLoadingEvents) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              const Color(0xFF0B2244),
          borderRadius:
              BorderRadius.circular(21),
          border: Border.all(
            color:
                const Color(0xFF153A69),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    Color(0xFF2388FF),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading upcoming event...',
              style: TextStyle(
                color:
                    Color(0xFF9CB5D0),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (event == null) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              const Color(0xFF0B2244),
          borderRadius:
              BorderRadius.circular(21),
          border: Border.all(
            color:
                const Color(0xFF153A69),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF2388FF)
                        .withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons
                    .event_available_rounded,
                color:
                    Color(0xFF5EA9FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'No upcoming events available.',
                    style: TextStyle(
                      color:
                          Color(0xFF809BB8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                EventDetailsScreen(
              event: event,
              canDelete: false,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(19),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(21),
          gradient:
              const LinearGradient(
            colors: [
              Color(0xFF0D3B78),
              Color(0xFF092850),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color:
                const Color(0xFF1B5CA8),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF0D6EFD)
                      .withOpacity(0.10),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFF2388FF)
                            .withOpacity(0.14),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color:
                        Color(0xFF62ADFF),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'UPCOMING EVENT',
                    style: TextStyle(
                      color:
                          Color(0xFF69B0FF),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                      Color(0xFF6C91B7),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              event['title']?.toString() ??
                  'Untitled Event',
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if ((event['description']
                        ?.toString()
                        .trim() ??
                    '')
                .isNotEmpty)
              Text(
                event['description']
                    .toString(),
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      Color(0xFF9DB9D7),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildEventInfo(
                    Icons
                        .calendar_month_rounded,
                    _formatEventDate(event),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEventInfo(
                    Icons.access_time_rounded,
                    _formatEventTime(event),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            if ((event['location']
                        ?.toString()
                        .trim() ??
                    '')
                .isNotEmpty)
              _buildEventInfo(
                Icons.location_on_outlined,
                event['location'].toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              const Color(0xFF6BAFFF),
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  Color(0xFFB4CBE4),
              fontSize: 10,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROGRESS CARD
  // ============================================================

  Widget _buildProgressCard() {
    final percentage =
        (completionPercentage * 100).round();

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color:
            const Color(0xFF0B2244),
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color:
              const Color(0xFF153A69),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Task completion overview',
                      style: TextStyle(
                        color:
                            Color(0xFF7895B7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color:
                      Color(0xFF4FA1FF),
                  fontSize: 23,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value:
                  completionPercentage,
              minHeight: 8,
              backgroundColor:
                  const Color(0xFF15345D),
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Color(0xFF2388FF),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  'Total',
                  totalTaskCount.toString(),
                  const Color(0xFF3D9BFF),
                ),
              ),
              Expanded(
                child: _buildProgressItem(
                  'Pending',
                  pendingTaskCount.toString(),
                  const Color(0xFFFBBF24),
                ),
              ),
              Expanded(
                child: _buildProgressItem(
                  'Working',
                  inProcessTaskCount.toString(),
                  const Color(0xFF38BDF8),
                ),
              ),
              Expanded(
                child: _buildProgressItem(
                  'Done',
                  completedTaskCount.toString(),
                  const Color(0xFF36D399),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      Color(0xFF718DAE),
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LATEST TASKS
  // ============================================================

  Widget _buildLatestTasks() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Latest Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const VolunteerTasksScreen(),
                  ),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color:
                      Color(0xFF55A7FF),
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        if (_isLoadingTasks)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF0B2244),
              borderRadius:
                  BorderRadius.circular(19),
              border: Border.all(
                color:
                    const Color(0xFF153A69),
              ),
            ),
            child: const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF2388FF),
                strokeWidth: 2,
              ),
            ),
          )
        else if (latestTasks.isEmpty)
          _buildEmptyTasks()
        else
          Column(
            children:
                latestTasks.map((task) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 9,
                ),
                child:
                    _buildTaskCard(task),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyTasks() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:
            const Color(0xFF0B2244),
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color:
              const Color(0xFF153A69),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .assignment_turned_in_outlined,
            color:
                Color(0xFF4C77A3),
            size: 34,
          ),
          SizedBox(height: 9),
          Text(
            'No tasks assigned yet',
            style: TextStyle(
              color:
                  Color(0xFFB1C8DF),
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your assigned tasks will appear here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Color(0xFF718CA9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    Map<String, dynamic> task,
  ) {
    final status =
        TaskService.getStatus(task);

    final statusColor =
        _statusColor(status);

    final title =
        TaskService.getTitle(task);

    final description =
        TaskService.getDescription(task);

    final points =
        TaskService.getPoints(task);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            const Color(0xFF0B2244),
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color:
              const Color(0xFF153A69),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  statusColor
                      .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              status == 'Done'
                  ? Icons
                      .check_circle_rounded
                  : status == 'In Process'
                      ? Icons.sync_rounded
                      : Icons
                          .pending_actions_rounded,
              color: statusColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    if (points > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+$points pts',
                        style:
                            const TextStyle(
                          color:
                              Color(0xFFFBBF24),
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                if (description
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF7895B7),
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            statusColor
                                .withOpacity(
                          0.10,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color:
                              statusColor,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons
                          .calendar_today_rounded,
                      color:
                          Color(0xFF647F9E),
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatTaskDeadline(
                          task,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF728CA9),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _buildQuickCard(
                icon:
                    Icons.assignment_rounded,
                title: 'Tasks',
                value:
                    totalTaskCount.toString(),
                color:
                    const Color(0xFF3D9BFF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const VolunteerTasksScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickCard(
                icon:
                    Icons.stars_rounded,
                title: 'Points',
                value:
                    completedPoints
                        .toString(),
                color:
                    const Color(0xFFFBBF24),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickCard(
                icon:
                    Icons.emoji_events_rounded,
                title: 'Rank',
                value: '#8',
                color:
                    const Color(0xFFA78BFA),
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const VolunteerEventsScreen(),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF0B2244),
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color:
                    const Color(0xFF153A69),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons
                      .event_note_rounded,
                  color:
                      Color(0xFF5EA9FF),
                  size: 21,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'All Events',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'View all upcoming and past events',
                        style:
                            TextStyle(
                          color:
                              Color(0xFF748FAC),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                      Color(0xFF617D9C),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUICK CARD
  // ============================================================

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFF0B2244),
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color:
                const Color(0xFF153A69),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 37,
              height: 37,
              decoration:
                  BoxDecoration(
                color:
                    color.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: color,
                size: 19,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color:
                    Color(0xFF7895B7),
                fontSize: 9,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}