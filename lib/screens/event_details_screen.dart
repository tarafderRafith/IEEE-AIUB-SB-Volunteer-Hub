import 'package:flutter/material.dart';

import '../services/database_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final bool canDelete;

  const EventDetailsScreen({
    super.key,
    required this.event,
    this.canDelete = false,
  });

  @override
  State<EventDetailsScreen> createState() =>
      _EventDetailsScreenState();
}

class _EventDetailsScreenState
    extends State<EventDetailsScreen> {
  bool _isDeleting = false;

  String _value(
    String key, [
    String fallback = 'Not available',
  ]) {
    final value = widget.event[key]?.toString();

    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value;
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _deleteEvent() async {
    final eventId = widget.event['id'];

    if (eventId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A2348),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete Event?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This event will be permanently removed.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
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
                'DELETE',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final success = await DatabaseService.deleteEvent(
      int.tryParse(eventId.toString()) ?? -1,
    );

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete event.',
          ),
          backgroundColor: Color(0xFFB3261E),
        ),
      );

      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = _value(
      'title',
      'Untitled Event',
    );

    final description = _value(
      'description',
      'No description available.',
    );

    final date = _value('date');
    final time = _value('time');

    final location = _value(
      'location',
    );

    final eventType = _value(
      'event_type',
      'Other',
    );

    final organizer = _value(
      'organizer',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF041329),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041329),
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
          'Event Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (widget.canDelete)
            IconButton(
              onPressed: _isDeleting
                  ? null
                  : _deleteEvent,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF6B6B),
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF6B6B),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          35,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
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
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                    child: Text(
                      eventType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            _sectionTitle('EVENT INFORMATION'),

            const SizedBox(height: 11),

            _infoCard(
              icon: Icons.calendar_month_rounded,
              title: 'Date',
              value: _formatDate(date),
            ),

            const SizedBox(height: 10),

            _infoCard(
              icon: Icons.access_time_rounded,
              title: 'Time',
              value: time,
            ),

            const SizedBox(height: 10),

            _infoCard(
              icon: Icons.location_on_outlined,
              title: 'Location',
              value: location,
            ),

            const SizedBox(height: 10),

            _infoCard(
              icon: Icons.person_outline_rounded,
              title: 'Organizer',
              value: organizer,
            ),

            const SizedBox(height: 24),

            _sectionTitle('EVENT STATUS'),

            const SizedBox(height: 11),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2348),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF55D88A)
                      .withOpacity(0.18),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF55D88A),
                    size: 23,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Event',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'This event is available to branch members.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF6EA6FF),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2348),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5BD7)
                  .withOpacity(0.13),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4D91FF),
              size: 20,
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
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}