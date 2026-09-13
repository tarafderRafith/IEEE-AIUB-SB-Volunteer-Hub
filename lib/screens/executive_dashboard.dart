import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'assign_task_screen.dart';
import 'login_screen.dart';

class ExecutiveDashboard extends StatefulWidget {
  const ExecutiveDashboard({super.key});

  @override
  State<ExecutiveDashboard> createState() =>
      _ExecutiveDashboardState();
}

class _ExecutiveDashboardState
    extends State<ExecutiveDashboard> {
  String get name =>
      AuthService.fullName ?? 'Executive';

  String get team =>
      AuthService.team ?? 'Team not assigned';

  String get position =>
      AuthService.executivePosition ?? 'Executive';

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

  void _openAssignTask() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssignTaskScreen(),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041329),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF3D8BFF),
          backgroundColor: const Color(0xFF0A2348),
          onRefresh: () async {
            setState(() {});
          },
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

                _buildSectionTitle(
                  'RECENT TASK ACTIVITY',
                ),

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
                overflow: TextOverflow.ellipsis,
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
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _logout,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF0A2348),
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
        borderRadius: BorderRadius.circular(24),
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
                Text(
                  'Manage volunteers, tasks, events and branch activities from one place.',
                  style: const TextStyle(
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
              color: Colors.white.withOpacity(0.10),
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
          onTap: () {
            _showComingSoon('Create Event');
          },
        ),
        _managementCard(
          icon: Icons.groups_rounded,
          title: 'Volunteers',
          subtitle: 'View volunteer members',
          onTap: () {
            _showComingSoon('Volunteer Management');
          },
        ),
        _managementCard(
          icon: Icons.campaign_rounded,
          title: 'Announcement',
          subtitle: 'Notify the branch',
          onTap: () {
            _showComingSoon('Announcements');
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
                  color: const Color(0xFF4D91FF),
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
            value: '30',
            label: 'Volunteers',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            icon: Icons.assignment_rounded,
            value: '18',
            label: 'Active Tasks',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _overviewCard(
            icon: Icons.event_rounded,
            value: '4',
            label: 'Events',
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
      padding: const EdgeInsets.symmetric(
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showComingSoon('Event Details');
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
              color: Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPAVe 8.0',
                      style: TextStyle(
                        color: Color(0xFF6EA6FF),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Academic Research Event',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '6 Aug 2026 • 2:00 PM',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
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
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        _activityCard(
          name: 'Volunteer A',
          task: 'Completed Promotional Campaign',
          status: 'Completed',
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(height: 10),
        _activityCard(
          name: 'Volunteer B',
          task: 'Started Event Registration Desk',
          status: 'In Process',
          icon: Icons.timelapse_rounded,
        ),
        const SizedBox(height: 10),
        _activityCard(
          name: 'Volunteer C',
          task: 'New task assigned',
          status: 'Pending',
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }

  Widget _activityCard({
    required String name,
    required String task,
    required String status,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2348),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5BD7)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4D91FF),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0D5BD7)
                  .withOpacity(0.18),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF6EA6FF),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}