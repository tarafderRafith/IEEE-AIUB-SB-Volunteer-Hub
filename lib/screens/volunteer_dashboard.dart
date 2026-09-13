import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'event_details_screen.dart';
import 'login_screen.dart';
import 'volunteer_tasks_screen.dart';
import 'volunteer_events_screen.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() =>
      _VolunteerDashboardState();
}

class _VolunteerDashboardState
    extends State<VolunteerDashboard> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _events = [];

  bool _isLoadingTasks = true;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();

    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadTasks(),
      _loadEvents(),
    ]);
  }

  Future<void> _loadTasks() async {
    final memberId = AuthService.memberId;

    if (memberId == null || memberId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _tasks = [];
        _isLoadingTasks = false;
      });

      return;
    }

    try {
      final loadedTasks =
          await DatabaseService.getTasksForVolunteer(
        memberId,
      );

      if (!mounted) return;

      setState(() {
        _tasks = loadedTasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    try {
      final loadedEvents =
          await DatabaseService.getAllEvents();

      if (!mounted) return;

      setState(() {
        _events = loadedEvents;
        _isLoadingEvents = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _events = [];
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  int get totalPoints {
    int total = 0;

    for (final task in _tasks) {
      final points = int.tryParse(
        task['points']?.toString() ?? '0',
      );

      total += points ?? 0;
    }

    return total;
  }

  List<Map<String, dynamic>> get latestTasks {
    if (_tasks.length <= 2) {
      return _tasks;
    }

    return _tasks.take(2).toList();
  }

  DateTime? _parseEventDateTime(
    Map<String, dynamic> event,
  ) {
    final dateString =
        event['date']?.toString().trim();

    if (dateString == null ||
        dateString.isEmpty) {
      return null;
    }

    final timeString =
        event['time']?.toString().trim();

    try {
      DateTime parsedDate =
          DateTime.parse(dateString);

      if (timeString == null ||
          timeString.isEmpty) {
        return parsedDate;
      }

      int hour = 0;
      int minute = 0;

      final normalizedTime =
          timeString.toUpperCase();

      final amPmMatch = RegExp(
        r'^(\d{1,2}):?(\d{2})?\s*(AM|PM)$',
      ).firstMatch(normalizedTime);

      if (amPmMatch != null) {
        hour = int.tryParse(
              amPmMatch.group(1) ?? '0',
            ) ??
            0;

        minute = int.tryParse(
              amPmMatch.group(2) ?? '0',
            ) ??
            0;

        final period =
            amPmMatch.group(3);

        if (period == 'PM' && hour < 12) {
          hour += 12;
        }

        if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      } else {
        final parts =
            normalizedTime.split(':');

        if (parts.isNotEmpty) {
          hour = int.tryParse(
                parts[0].trim(),
              ) ??
              0;
        }

        if (parts.length > 1) {
          final minutePart =
              parts[1]
                  .replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  )
                  .trim();

          minute = int.tryParse(
                minutePart.isEmpty
                    ? '0'
                    : minutePart,
              ) ??
              0;
        }
      }

      return DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get _upcomingEvent {
    if (_events.isEmpty) {
      return null;
    }

    final now = DateTime.now();

    final upcomingEvents =
        _events.where((event) {
      final eventDate =
          _parseEventDateTime(event);

      if (eventDate == null) {
        return false;
      }

      return eventDate.isAfter(now);
    }).toList();

    if (upcomingEvents.isEmpty) {
      return null;
    }

    upcomingEvents.sort((a, b) {
      final dateA =
          _parseEventDateTime(a);

      final dateB =
          _parseEventDateTime(b);

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

    return upcomingEvents.first;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Done':
        return const Color(0xFF36D399);

      case 'In Process':
        return const Color(0xFFFFB84D);

      default:
        return const Color(0xFF5EA0FF);
    }
  }

  IconData _taskIcon(String title) {
    final lowerTitle =
        title.toLowerCase();

    if (lowerTitle.contains('social') ||
        lowerTitle.contains('facebook') ||
        lowerTitle.contains('instagram') ||
        lowerTitle.contains('content') ||
        lowerTitle.contains('promotion')) {
      return Icons.campaign_outlined;
    }

    if (lowerTitle.contains('registration')) {
      return Icons.assignment_outlined;
    }

    if (lowerTitle.contains('design') ||
        lowerTitle.contains('creative') ||
        lowerTitle.contains('poster')) {
      return Icons.palette_outlined;
    }

    if (lowerTitle.contains('web') ||
        lowerTitle.contains('website') ||
        lowerTitle.contains('development')) {
      return Icons.language_outlined;
    }

    if (lowerTitle.contains('event')) {
      return Icons.event_outlined;
    }

    if (lowerTitle.contains('research')) {
      return Icons.menu_book_outlined;
    }

    if (lowerTitle.contains('photo') ||
        lowerTitle.contains('video')) {
      return Icons.photo_library_outlined;
    }

    return Icons.task_alt_rounded;
  }

  Future<void> _openEvents(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const VolunteerEventsScreen(),
      ),
    );

    if (!mounted) return;

    await _loadEvents();
  }

  Future<void> _openEventDetails(
    Map<String, dynamic> event,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EventDetailsScreen(
          event: event,
          canDelete: false,
        ),
      ),
    );

    if (!mounted) return;

    await _loadEvents();
  }

  Future<void> _openTasks(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const VolunteerTasksScreen(),
      ),
    );

    if (!mounted) return;

    await _loadTasks();
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF091F40),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.white60,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                AuthService.clear();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF0D5BD7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text('LOGOUT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        AuthService.fullName ?? 'Volunteer';

    final team =
        AuthService.team ?? 'Team not assigned';

    return Scaffold(
      backgroundColor:
          const Color(0xFF041329),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF3D8BFF),
          backgroundColor:
              const Color(0xFF0A2145),
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF3E8BFF),
                            Color(0xFF0D5BD7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0D5BD7)
                                    .withOpacity(0.4),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                color:
                                    Color(0xFF4D91FF),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  team,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(0xFF5EA0FF),
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _logout(context),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(0xFF0A2145),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          border: Border.all(
                            color:
                                const Color(0xFF173D72),
                          ),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color:
                              Color(0xFF4D91FF),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(25),
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF0D5BD7),
                        Color(0xFF082E70),
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
                                .withOpacity(0.3),
                        blurRadius: 25,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'IEEE AIUB',
                            style: TextStyle(
                              color:
                                  Colors.white70,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Volunteer Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Make an impact. Complete your tasks. '
                        'Grow with the branch.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Upcoming Event',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _openEvents(context),
                      child: const Row(
                        children: [
                          Text(
                            'All Events',
                            style: TextStyle(
                              color:
                                  Color(0xFF4D91FF),
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            color:
                                Color(0xFF4D91FF),
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _eventCard(),

                const SizedBox(height: 28),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Tasks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior:
                          HitTestBehavior.opaque,
                      onTap: () =>
                          _openTasks(context),
                      child: const Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              color:
                                  Color(0xFF4D91FF),
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons
                                .arrow_forward_ios_rounded,
                            color:
                                Color(0xFF4D91FF),
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (_isLoadingTasks)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 35,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF091F40),
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            const Color(0xFF173D72),
                      ),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:
                              Color(0xFF4D91FF),
                        ),
                      ),
                    ),
                  )
                else if (latestTasks.isEmpty)
                  _emptyTaskCard()
                else
                  ...latestTasks.map(
                    (task) {
                      final title =
                          task['title']
                                  ?.toString() ??
                              'Untitled Task';

                      final description =
                          task['description']
                                  ?.toString() ??
                              'No description';

                      final status =
                          task['status']
                                  ?.toString() ??
                              'Pending';

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: GestureDetector(
                          behavior:
                              HitTestBehavior.opaque,
                          onTap: () =>
                              _openTasks(context),
                          child: _taskCard(
                            title: title,
                            subtitle:
                                description,
                            status: status,
                            icon:
                                _taskIcon(title),
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _quickCard(
                        icon:
                            Icons.task_alt_rounded,
                        title: 'Tasks',
                        value:
                            '${_tasks.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickCard(
                        icon:
                            Icons.stars_rounded,
                        title: 'Points',
                        value:
                            '$totalPoints',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickCard(
                        icon:
                            Icons.emoji_events_rounded,
                        title: 'Rank',
                        value: '#8',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyTaskCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF091F40),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF173D72),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5BD7)
                  .withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF4D91FF),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'No tasks assigned yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your assigned tasks will appear here.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard() {
    if (_isLoadingEvents) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF091F40),
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF173D72),
          ),
        ),
        child: const Column(
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF4D91FF),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading upcoming event...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final event = _upcomingEvent;

    if (event == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF091F40),
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF173D72),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D5BD7)
                  .withOpacity(0.08),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF0D5BD7)
                    .withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF4D91FF),
                size: 29,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'No upcoming events',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'There are no future branch events at the moment.',
                    style: TextStyle(
                      color: Colors.white54,
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

    final title =
        event['title']?.toString() ??
            'Untitled Event';

    final description =
        event['description']?.toString() ??
            '';

    final eventType =
        event['event_type']?.toString() ??
            'Event';

    final date =
        event['date']?.toString() ??
            'Date not set';

    final time =
        event['time']?.toString() ??
            'Time not set';

    final location =
        event['location']?.toString() ??
            'Location not set';

    final organizer =
        event['organizer']?.toString() ??
            'Organizer not set';

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,
      onTap: () =>
          _openEventDetails(event),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF091F40),
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF173D72),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D5BD7)
                  .withOpacity(0.12),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        Color(0xFF0D5BD7),
                        Color(0xFF123C82),
                      ],
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
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
                      Text(
                        eventType.toUpperCase(),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:
                              Color(0xFF5EA0FF),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),

            const SizedBox(height: 15),

            if (description.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Text(
                  description,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF061A36),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_rounded,
                        color:
                            Color(0xFF4D91FF),
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          date,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time_rounded,
                        color:
                            Color(0xFF4D91FF),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          time,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color:
                            Color(0xFF4D91FF),
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color:
                            Color(0xFF4D91FF),
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Organized by $organizer',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                const Text(
                  'VIEW DETAILS',
                  style: TextStyle(
                    color:
                        Color(0xFF5EA0FF),
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color:
                      Color(0xFF5EA0FF),
                  size: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskCard({
    required String title,
    required String subtitle,
    required String status,
    required IconData icon,
  }) {
    final statusColor =
        _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF091F40),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF173D72),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5BD7)
                  .withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4D91FF),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor
                  .withOpacity(0.15),
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color: statusColor
                    .withOpacity(0.25),
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF091F40),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF173D72),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4D91FF),
            size: 25,
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}