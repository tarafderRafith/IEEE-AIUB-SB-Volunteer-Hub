import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'event_details_screen.dart';

class VolunteerEventsScreen
    extends StatefulWidget {
  const VolunteerEventsScreen({
    super.key,
  });

  @override
  State<VolunteerEventsScreen>
      createState() =>
          _VolunteerEventsScreenState();
}

class _VolunteerEventsScreenState
    extends State<VolunteerEventsScreen> {
  List<Map<String, dynamic>> _events = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final events =
          await DatabaseService.getAllEvents();

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Event loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF041329),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF041329),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadEvents,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF6EA6FF),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF3D8BFF),
        backgroundColor:
            const Color(0xFF0A2348),
        onRefresh: _loadEvents,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3D8BFF),
        ),
      );
    }

    if (_events.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 130),
          _emptyState(),
        ],
      );
    }

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        35,
      ),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];

        return Padding(
          padding:
              const EdgeInsets.only(bottom: 12),
          child: _eventCard(event),
        );
      },
    );
  }

  Widget _eventCard(
    Map<String, dynamic> event,
  ) {
    final title =
        event['title']?.toString() ??
            'Untitled Event';

    final description =
        event['description']?.toString() ??
            '';

    final date =
        event['date']?.toString() ??
            '';

    final time =
        event['time']?.toString() ??
            '';

    final location =
        event['location']?.toString() ??
            '';

    final eventType =
        event['event_type']?.toString() ??
            'Other';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result =
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

          if (result == true) {
            await _loadEvents();
          }
        },
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
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color(0xFF0D5BD7),
                          Color(0xFF123C82),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 23,
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
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          eventType,
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF6EA6FF),
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white30,
                    size: 15,
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

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _smallInfo(
                      icon:
                          Icons.calendar_month_outlined,
                      value:
                          _formatDate(date),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallInfo(
                      icon:
                          Icons.access_time_rounded,
                      value: time,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              _smallInfo(
                icon:
                    Icons.location_on_outlined,
                value: location,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallInfo({
    required IconData icon,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4D91FF),
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2348),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            color: Color(0xFF4D91FF),
            size: 48,
          ),
          SizedBox(height: 15),
          Text(
            'No Upcoming Events',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Events created by the executive team will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}