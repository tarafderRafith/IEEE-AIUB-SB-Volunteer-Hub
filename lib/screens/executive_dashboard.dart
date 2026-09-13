import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'assign_task_screen.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'executive_task_details_screen.dart';
import 'login_screen.dart';

class ExecutiveDashboard extends StatefulWidget {
  const ExecutiveDashboard({super.key});

  @override
  State<ExecutiveDashboard> createState() =>
      _ExecutiveDashboardState();
}

class _ExecutiveDashboardState extends State<ExecutiveDashboard> {
  List<Map<String, dynamic>> _assignedTasks = [];
  List<Map<String, dynamic>> _events = [];

  int _volunteerCount = 0;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingEvents = true;

  Timer? _liveRefreshTimer;

  String get name =>
      AuthService.fullName ?? 'Executive';

  String get team =>
      AuthService.team ?? 'Team not assigned';

  String get position =>
      AuthService.executivePosition ?? 'Executive';

  @override
  void initState() {
    super.initState();

    _loadDashboardData();

    _liveRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _loadDashboardData(
          silent: true,
        );
      },
    );
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({
    bool silent = false,
  }) async {
    final executiveMemberId = AuthService.memberId;

    if (executiveMemberId == null ||
        executiveMemberId.isEmpty) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _isLoadingEvents = false;
        });
      }

      return;
    }

    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingEvents = true;
      });
    }

    try {
      final results = await Future.wait([
        DatabaseService.getTasksAssignedByExecutive(
          executiveMemberId,
        ),
        DatabaseService.getVolunteers(),
        DatabaseService.getAllEvents(),
      ]);

      final tasks =
          results[0] as List<Map<String, dynamic>>;

      final volunteers =
          results[1] as List<Map<String, dynamic>>;

      final events =
          results[2] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        _assignedTasks = tasks;
        _volunteerCount = volunteers.length;
        _events = events;
        _isLoading = false;
        _isLoadingEvents = false;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint(
        'Executive dashboard loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingEvents = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadDashboardData(
      silent: true,
    );

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A2348),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'LOGOUT',
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

    if (shouldLogout != true) {
      return;
    }

    AuthService.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _openAssignTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssignTaskScreen(),
      ),
    );

    await _loadDashboardData();
  }

  Future<void> _openCreateEvent() async {
    final eventCreated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    );

    if (!mounted) return;

    if (eventCreated == true) {
      await _loadDashboardData();
    }
  }

  Future<void> _openEventDetails(
    Map<String, dynamic> event,
  ) async {
    final eventDeleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          event: event,
          canDelete: true,
        ),
      ),
    );

    if (!mounted) return;

    if (eventDeleted == true) {
      await _loadDashboardData();
    } else {
      await _loadDashboardData(
        silent: true,
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be available in the next phase.',
        ),
        backgroundColor: const Color(0xFF0D5BD7),
      ),
    );
  }

  Future<void> _openTaskDetails(
    Map<String, dynamic> task,
  ) async {
    final taskDeleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExecutiveTaskDetailsScreen(
          task: task,
        ),
      ),
    );

    if (!mounted) return;

    if (taskDeleted == true) {
      await _loadDashboardData();
    } else {
      await _loadDashboardData(
        silent: true,
      );
    }
  }

  int get _activeTaskCount {
    return _assignedTasks.where((task) {
      final status =
          task['status']?.toString() ?? 'Pending';

      return status == 'Pending' ||
          status == 'In Process';
    }).length;
  }

  int get _completedTaskCount {
    return _assignedTasks.where((task) {
      final status =
          task['status']?.toString() ?? 'Pending';

      return status == 'Done';
    }).length;
  }

  DateTime? _getEventDateTime(
    Map<String, dynamic> event,
  ) {
    final rawDate =
        event['date']?.toString().trim() ?? '';

    final rawTime =
        event['time']?.toString().trim() ?? '';

    if (rawDate.isEmpty) {
      return null;
    }

    DateTime? parsedDateTime;

    if (rawTime.isNotEmpty) {
      parsedDateTime = DateTime.tryParse(
        '$rawDate $rawTime',
      );
    }

    parsedDateTime ??= DateTime.tryParse(rawDate);

    return parsedDateTime;
  }

  Map<String, dynamic>? get _upcomingEvent {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041329),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF3D8BFF),
          backgroundColor: const Color(0xFF0A2348),
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              35,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 28),

                _buildWelcomeCard(),

                const SizedBox(height: 25),

                _buildSectionTitle(
                  'MANAGEMENT',
                ),

                const SizedBox(height: 12),

                _buildManagementGrid(),

                const SizedBox(height: 28),

                _buildSectionTitle(
                  'BRANCH OVERVIEW',
                ),

                const SizedBox(height: 12),

                _buildOverview(),

                const SizedBox(height: 28),

                _buildSectionTitle(
                  'UPCOMING EVENT',
                ),

                const SizedBox(height: 12),

                _buildUpcomingEvent(),

                const SizedBox(height: 28),

                _buildTaskActivityHeader(),

                const SizedBox(height: 12),

                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3D8BFF),
                Color(0xFF0D5BD7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D5BD7)
                    .withOpacity(0.35),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
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
              Text(
                name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$position • $team',
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
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0D5BD7)
                .withOpacity(0.15),
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF3D8BFF)
                  .withOpacity(0.20),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(),
              SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFF6EA6FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        IconButton(
          onPressed: _logout,
          style: IconButton.styleFrom(
            backgroundColor:
                const Color(0xFF0A2348),
          ),
          icon: const Icon(
            Icons.logout_rounded,
            color: Colors.white70,
            size: 21,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D5BD7),
            Color(0xFF08295F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5BD7)
                .withOpacity(0.25),
            blurRadius: 28,
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
                  'Executive Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage volunteers, tasks, events and branch activities from one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 29,
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

  Widget _buildManagementGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.28,
      children: [
        _managementCard(
          icon: Icons.assignment_rounded,
          title: 'Assign Task',
          subtitle: 'Give work to volunteers',
          onTap: _openAssignTask,
        ),
        _managementCard(
          icon: Icons.event_available_rounded,
          title: 'Create Event',
          subtitle: 'Manage branch events',
          onTap: _openCreateEvent,
        ),
        _managementCard(
          icon: Icons.groups_rounded,
          title: 'Volunteers',
          subtitle: 'View volunteer members',
          onTap: () {
            _showComingSoon(
              'Volunteer Management',
            );
          },
        ),
        _managementCard(
          icon: Icons.campaign_rounded,
          title: 'Announcement',
          subtitle: 'Notify the branch',
          onTap: () {
            _showComingSoon(
              'Announcements',
            );
          },
        ),
      ],
    );
  }

  Widget _managementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2348),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5BD7)
                      .withOpacity(0.18),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF4D91FF),
                  size: 23,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
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
      ),
    );
  }

  Widget _buildOverview() {
    return Row(
      children: [
        Expanded(
          child: _overviewCard(
            icon: Icons.groups_rounded,
            value:
                _volunteerCount.toString(),
            label: 'Volunteers',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            icon: Icons.assignment_rounded,
            value:
                _activeTaskCount.toString(),
            label: 'Active Tasks',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            icon:
                Icons.check_circle_rounded,
            value:
                _completedTaskCount.toString(),
            label: 'Completed',
          ),
        ),
      ],
    );
  }

  Widget _overviewCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2348),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4D91FF),
            size: 23,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvent() {
    if (_isLoadingEvents) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2348),
          borderRadius:
              BorderRadius.circular(21),
          border: Border.all(
            color: Colors.white10,
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
              'Loading events...',
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
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openCreateEvent,
          borderRadius:
              BorderRadius.circular(21),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2348),
              borderRadius:
                  BorderRadius.circular(21),
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
                    color: const Color(0xFF0D5BD7)
                        .withOpacity(0.16),
                    borderRadius:
                        BorderRadius.circular(17),
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
                              FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Create a new branch event to see it here.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF6EA6FF),
                  size: 22,
                ),
              ],
            ),
          ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openEventDetails(event);
        },
        borderRadius:
            BorderRadius.circular(21),
        child: Ink(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2348),
            borderRadius:
                BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFF3D8BFF)
                  .withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D5BD7)
                    .withOpacity(0.08),
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
                      ),
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Colors.white,
                      size: 28,
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
                                Color(0xFF6EA6FF),
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: 0.7,
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
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Colors.white30,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (description.isNotEmpty)
                Text(
                  description,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              if (description.isNotEmpty)
                const SizedBox(height: 13),
              Wrap(
                spacing: 14,
                runSpacing: 9,
                children: [
                  _eventInfoItem(
                    icon:
                        Icons.calendar_today_rounded,
                    text: date,
                  ),
                  _eventInfoItem(
                    icon: Icons.access_time_rounded,
                    text: time,
                  ),
                  _eventInfoItem(
                    icon:
                        Icons.location_on_outlined,
                    text: location,
                  ),
                  _eventInfoItem(
                    icon:
                        Icons.person_outline_rounded,
                    text: organizer,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF061A36),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'VIEW EVENT DETAILS',
                      style: TextStyle(
                        color:
                            Color(0xFF6EA6FF),
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons
                          .arrow_forward_rounded,
                      color:
                          Color(0xFF6EA6FF),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventInfoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white38,
          size: 14,
        ),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 210,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskActivityHeader() {
    return Row(
      children: [
        Expanded(
          child: _buildSectionTitle(
            'TASK ACTIVITY & HISTORY',
          ),
        ),
        if (_isRefreshing)
          const SizedBox(
            width: 15,
            height: 15,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4D91FF),
            ),
          )
        else
          IconButton(
            onPressed: _refreshDashboard,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(),
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF6EA6FF),
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoading &&
        _assignedTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          vertical: 35,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2348),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white10,
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
            SizedBox(height: 13),
            Text(
              'Loading task activity...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_assignedTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 35,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2348),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              color: Color(0xFF4D91FF),
              size: 38,
            ),
            SizedBox(height: 12),
            Text(
              'No tasks assigned yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Tasks you assign to volunteers will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(
        _assignedTasks.length,
        (index) {
          final task =
              _assignedTasks[index];

          return Padding(
            padding:
                EdgeInsets.only(
              bottom:
                  index ==
                          _assignedTasks.length -
                              1
                      ? 0
                      : 10,
            ),
            child: _activityCard(
              task: task,
            ),
          );
        },
      ),
    );
  }

  Widget _activityCard({
    required Map<String, dynamic> task,
  }) {
    final title =
        task['title']?.toString() ??
            'Untitled Task';

    final description =
        task['description']?.toString() ??
            '';

    final volunteerName =
        task['volunteer_name']?.toString() ??
            'Unknown Volunteer';

    final volunteerId =
        task['volunteer_member_id']
                ?.toString() ??
            '';

    final volunteerTeam =
        task['volunteer_team']?.toString() ??
            task['team']?.toString() ??
            'Team not assigned';

    final status =
        task['status']?.toString() ??
            'Pending';

    final priority =
        task['priority']?.toString() ??
            'Medium';

    final updatedAt =
        task['updated_at']?.toString();

    final startedAt =
        task['started_at']?.toString();

    final completedAt =
        task['completed_at']?.toString();

    final statusColor =
        _statusColor(status);

    final statusIcon =
        _statusIcon(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openTaskDetails(task);
        },
        borderRadius:
            BorderRadius.circular(19),
        child: Ink(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2348),
            borderRadius:
                BorderRadius.circular(19),
            border: Border.all(
              color: statusColor
                  .withOpacity(0.18),
            ),
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
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: statusColor
                          .withOpacity(0.13),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
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
                        const SizedBox(height: 5),
                        Text(
                          volunteerName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF6EA6FF),
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(
                    status,
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF061A36),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          color:
                              Colors.white38,
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            volunteerId.isEmpty
                                ? volunteerTeam
                                : '$volunteerId • $volunteerTeam',
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        _priorityBadge(
                          priority,
                        ),
                      ],
                    ),
                    if (description
                        .isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        description,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeline(
                status: status,
                updatedAt: updatedAt,
                startedAt: startedAt,
                completedAt:
                    completedAt,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  const Text(
                    'VIEW DETAILS',
                    style: TextStyle(
                      color:
                          Color(0xFF6EA6FF),
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                        Color(0xFF6EA6FF),
                    size: 15,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline({
    required String status,
    String? updatedAt,
    String? startedAt,
    String? completedAt,
  }) {
    final items = <Widget>[];

    if (updatedAt != null &&
        updatedAt.isNotEmpty) {
      items.add(
        _timelineItem(
          icon: Icons.update_rounded,
          title: 'Last updated',
          value:
              _formatRelativeTime(
            updatedAt,
          ),
          color:
              const Color(0xFF4D91FF),
        ),
      );
    }

    if (startedAt != null &&
        startedAt.isNotEmpty &&
        (status == 'In Process' ||
            status == 'Done')) {
      items.add(
        _timelineItem(
          icon:
              Icons.play_circle_outline,
          title: 'Started',
          value:
              _formatRelativeTime(
            startedAt,
          ),
          color:
              const Color(0xFFFFB74D),
        ),
      );
    }

    if (completedAt != null &&
        completedAt.isNotEmpty &&
        status == 'Done') {
      items.add(
        _timelineItem(
          icon:
              Icons.check_circle_outline,
          title: 'Completed',
          value:
              _formatRelativeTime(
            completedAt,
          ),
          color:
              const Color(0xFF55D88A),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 15,
        ),
        const SizedBox(width: 5),
        Text(
          '$title: $value',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(
    String status,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _priorityBadge(
    String priority,
  ) {
    Color color;

    switch (priority.toLowerCase()) {
      case 'high':
        color = const Color(0xFFFF6B6B);
        break;

      case 'low':
        color = const Color(0xFF55D88A);
        break;

      default:
        color = const Color(0xFFFFB74D);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'In Process':
        return const Color(0xFFFFB74D);

      case 'Done':
        return const Color(0xFF55D88A);

      case 'Pending':
      default:
        return const Color(0xFF4D91FF);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'In Process':
        return Icons.timelapse_rounded;

      case 'Done':
        return Icons.check_circle_rounded;

      case 'Pending':
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _formatRelativeTime(
    String? dateString,
  ) {
    if (dateString == null ||
        dateString.isEmpty) {
      return 'Unknown';
    }

    final date =
        DateTime.tryParse(dateString);

    if (date == null) {
      return 'Unknown';
    }

    final now = DateTime.now();

    final difference =
        now.difference(date);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inSeconds < 10) {
      return 'Just now';
    }

    if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month ${hour.toString()}:$minute $period';
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF55D88A),
        shape: BoxShape.circle,
      ),
    );
  }
}