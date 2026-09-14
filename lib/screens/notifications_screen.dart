import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _notifications = [];

  Timer? _refreshTimer;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    debugPrint('');
    debugPrint('========================================');
    debugPrint('🔔 NOTIFICATIONS SCREEN INIT');
    debugPrint('========================================');

    _loadNotifications();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (mounted) {
          _loadNotifications(
            showLoading: false,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _refreshTimer?.cancel();
    _refreshTimer = null;

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        '🔔 App resumed → refreshing notifications',
      );

      _loadNotifications(
        showLoading: false,
      );
    }
  }

  Future<void> _loadNotifications({
    bool showLoading = true,
  }) async {
    final memberId =
        AuthService.memberId?.trim();

    debugPrint('');
    debugPrint(
      '🔔 ----------------------------------------',
    );
    debugPrint(
      '🔔 LOADING NOTIFICATIONS',
    );
    debugPrint(
      '🔔 AuthService.memberId: $memberId',
    );
    debugPrint(
      '🔔 ----------------------------------------',
    );

    if (memberId == null ||
        memberId.isEmpty) {
      debugPrint(
        '❌ Notifications: member ID is null/empty',
      );

      if (!mounted) return;

      setState(() {
        _notifications = [];
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage =
            'No logged-in member found.';
      });

      return;
    }

    if (showLoading) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isRefreshing = true;
        });
      }
    }

    try {
      debugPrint(
        '🔎 Requesting notifications for member ID: $memberId',
      );

      final notifications =
          await DatabaseService
              .getNotificationsForMember(
        memberId,
      );

      debugPrint(
        '✅ Notifications returned: ${notifications.length}',
      );

      for (final notification
          in notifications) {
        debugPrint(
          '🔔 Notification: '
          'id=${notification['id']}, '
          'recipient=${notification['recipient_member_id']}, '
          'title=${notification['title']}, '
          'type=${notification['type']}, '
          'read=${notification['is_read']}',
        );
      }

      if (!mounted) return;

      setState(() {
        _notifications =
            List<Map<String, dynamic>>.from(
          notifications,
        );

        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });

      debugPrint(
        '✅ Notifications state updated successfully.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Failed to load notifications: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage =
            'Failed to load notifications.';
      });
    }
  }

  Future<void> _markAsRead(
    int notificationId,
  ) async {
    try {
      final success =
          await DatabaseService
              .markNotificationAsRead(
        notificationId,
      );

      debugPrint(
        '🔔 Mark notification $notificationId as read: $success',
      );

      if (!mounted) return;

      setState(() {
        final index =
            _notifications.indexWhere(
          (notification) =>
              notification['id'] ==
              notificationId,
        );

        if (index != -1) {
          _notifications[index] = {
            ..._notifications[index],
            'is_read': 1,
          };
        }
      });
    } catch (e) {
      debugPrint(
        '❌ Failed to mark notification as read: $e',
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final memberId =
        AuthService.memberId?.trim();

    if (memberId == null ||
        memberId.isEmpty) {
      return;
    }

    try {
      await DatabaseService
          .markAllNotificationsAsRead(
        memberId,
      );

      if (!mounted) return;

      setState(() {
        _notifications =
            _notifications.map(
          (notification) {
            return {
              ...notification,
              'is_read': 1,
            };
          },
        ).toList();
      });

      _showMessage(
        'All notifications marked as read.',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to mark all notifications as read: $e',
      );

      _showMessage(
        'Failed to update notifications.',
        isError: true,
      );
    }
  }

  Future<void> _deleteNotification(
    int notificationId,
  ) async {
    try {
      final success =
          await DatabaseService
              .deleteNotification(
        notificationId,
      );

      if (!success) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _notifications.removeWhere(
          (notification) =>
              notification['id'] ==
              notificationId,
        );
      });

      _showMessage(
        'Notification deleted.',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to delete notification: $e',
      );

      _showMessage(
        'Failed to delete notification.',
        isError: true,
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final memberId =
        AuthService.memberId?.trim();

    if (memberId == null ||
        memberId.isEmpty) {
      return;
    }

    if (_notifications.isEmpty) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF0A2348),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear All Notifications?',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            'All your notifications will be permanently removed.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color:
                      Colors.white60,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'CLEAR ALL',
                style: TextStyle(
                  color:
                      Color(0xFF4D91FF),
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await DatabaseService
          .deleteAllNotifications(
        memberId,
      );

      if (!mounted) return;

      setState(() {
        _notifications.clear();
      });

      _showMessage(
        'All notifications cleared.',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to clear notifications: $e',
      );

      _showMessage(
        'Failed to clear notifications.',
        isError: true,
      );
    }
  }

  void _openNotification(
    Map<String, dynamic> notification,
  ) {
    final id =
        notification['id'] as int?;

    if (id != null) {
      _markAsRead(id);
    }
  }

  int get _unreadCount {
    return _notifications.where(
      (notification) =>
          notification['is_read'] != 1,
    ).length;
  }

  IconData _getNotificationIcon(
    String type,
  ) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_rounded;

      case 'task_updated':
        return Icons.update_rounded;

      case 'task_completed':
        return Icons.task_alt_rounded;

      case 'event_created':
        return Icons.event_rounded;

      case 'event_updated':
        return Icons.event_available_rounded;

      case 'announcement':
        return Icons.campaign_rounded;

      case 'system':
        return Icons.notifications_rounded;

      default:
        return Icons
            .notifications_active_rounded;
    }
  }

  String _getNotificationLabel(
    String type,
  ) {
    switch (type) {
      case 'task_assigned':
        return 'TASK ASSIGNED';

      case 'task_updated':
        return 'TASK UPDATED';

      case 'task_completed':
        return 'TASK COMPLETED';

      case 'event_created':
        return 'NEW EVENT';

      case 'event_updated':
        return 'EVENT UPDATED';

      case 'announcement':
        return 'ANNOUNCEMENT';

      case 'system':
        return 'SYSTEM';

      default:
        return 'NOTIFICATION';
    }
  }

  Color _getNotificationColor(
    String type,
  ) {
    switch (type) {
      case 'task_assigned':
        return const Color(0xFF3D8BFF);

      case 'task_completed':
        return const Color(0xFF3DDC97);

      case 'event_created':
        return const Color(0xFF8C7CFF);

      case 'announcement':
        return const Color(0xFFFFB84D);

      default:
        return const Color(0xFF4D91FF);
    }
  }

  String _formatTime(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final date =
        DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    final now = DateTime.now();

    final difference =
        now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final hour =
        date.hour == 0
            ? 12
            : date.hour > 12
                ? date.hour - 12
                : date.hour;

    final minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '${date.day}/'
        '${date.month}/'
        '${date.year} '
        '$hour:$minute $period';
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

  Future<void> _handleRefresh() async {
    await _loadNotifications(
      showLoading: false,
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
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF0D5BD7,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  '$_unreadCount',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              tooltip:
                  'Mark all as read',
              onPressed:
                  _markAllAsRead,
              icon: const Icon(
                Icons.done_all_rounded,
                color:
                    Color(0xFF6EA6FF),
              ),
            ),
          if (_notifications
              .isNotEmpty)
            IconButton(
              tooltip:
                  'Clear all',
              onPressed:
                  _deleteAllNotifications,
              icon: const Icon(
                Icons
                    .delete_sweep_rounded,
                color:
                    Colors.white60,
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFF3D8BFF),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color:
          const Color(0xFF3D8BFF),
      backgroundColor:
          const Color(0xFF0A2348),
      onRefresh:
          _handleRefresh,
      child:
          _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildNotificationList() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        30,
      ),
      children: [
        _buildHeaderSummary(),

        const SizedBox(
          height: 16,
        ),

        if (_isRefreshing)
          const Padding(
            padding:
                EdgeInsets.only(
              bottom: 10,
            ),
            child:
                LinearProgressIndicator(
              minHeight: 2,
              backgroundColor:
                  Colors.transparent,
              color:
                  Color(0xFF3D8BFF),
            ),
          ),

        ..._notifications.map(
          (notification) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child:
                  _buildNotificationCard(
                notification,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
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
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons
                  .notifications_active_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(
            width: 15,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _unreadCount == 0
                      ? 'You are all caught up.'
                      : '$_unreadCount unread notification'
                          '${_unreadCount == 1 ? '' : 's'}',
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
  ) {
    final id =
        notification['id'] as int?;

    final title =
        notification['title']
                ?.toString() ??
            'Notification';

    final message =
        notification['message']
                ?.toString() ??
            '';

    final type =
        notification['type']
                ?.toString() ??
            'system';

    final isRead =
        notification['is_read'] == 1;

    final createdAt =
        notification['created_at'];

    final color =
        _getNotificationColor(type);

    return Dismissible(
      key: ValueKey(
        id ??
            '${title}_${createdAt}',
      ),
      direction:
          DismissDirection.endToStart,
      confirmDismiss:
          (_) async {
        if (id == null) {
          return false;
        }

        return true;
      },
      onDismissed: (_) {
        if (id != null) {
          _deleteNotification(id);
        }
      },
      background: Container(
        alignment:
            Alignment.centerRight,
        padding:
            const EdgeInsets.only(
          right: 25,
        ),
        decoration: BoxDecoration(
          color:
              const Color(0xFFB3261E),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          _openNotification(
            notification,
          );
        },
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 200,
          ),
          padding:
              const EdgeInsets.all(17),
          decoration:
              BoxDecoration(
            color: isRead
                ? const Color(
                    0xFF081C3A,
                  )
                : const Color(
                    0xFF0A2348,
                  ),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: isRead
                  ? Colors.white
                      .withOpacity(
                      0.06,
                    )
                  : color.withOpacity(
                      0.35,
                    ),
              width:
                  isRead ? 1 : 1.2,
            ),
            boxShadow: isRead
                ? []
                : [
                    BoxShadow(
                      color:
                          color.withOpacity(
                        0.08,
                      ),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(
                    0.14,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  _getNotificationIcon(
                    type,
                  ),
                  color: color,
                  size: 23,
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
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 15,
                              fontWeight:
                                  isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              left: 8,
                              top: 4,
                            ),
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(
                              color:
                                  color,
                              shape:
                                  BoxShape
                                      .circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Text(
                      message,
                      maxLines: 4,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white60,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
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
                                color.withOpacity(
                              0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              6,
                            ),
                          ),
                          child: Text(
                            _getNotificationLabel(
                              type,
                            ),
                            style:
                                TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              letterSpacing:
                                  0.7,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(
                            createdAt,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.20,
        ),
        Center(
          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 35,
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color:
                        const Color(
                      0xFF0D5BD7,
                    ).withOpacity(0.13),
                  ),
                  child:
                      const Icon(
                    Icons
                        .notifications_none_rounded,
                    color:
                        Color(0xFF4D91FF),
                    size: 52,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                const Text(
                  'No notifications yet',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'When an executive assigns you a task or sends an announcement, it will appear here.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.white54,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                Text(
                  'Pull down to refresh',
                  style:
                      const TextStyle(
                    color:
                        Colors.white30,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
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
                  0xFFB3261E,
                ).withOpacity(0.12),
              ),
              child:
                  const Icon(
                Icons
                    .error_outline_rounded,
                color:
                    Color(0xFFFF6B6B),
                size: 45,
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            const Text(
              'Unable to load notifications',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.white54,
                fontSize: 13,
              ),
            ),
            const SizedBox(
              height: 22,
            ),
            ElevatedButton(
              onPressed: () {
                _loadNotifications();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF0D5BD7,
                ),
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
              child: const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }
}