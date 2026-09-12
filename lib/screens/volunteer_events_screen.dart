import 'package:flutter/material.dart';
import 'event_details_screen.dart';

class VolunteerEventsScreen extends StatelessWidget {
  const VolunteerEventsScreen({super.key});

  void openSpave(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventDetailsScreen(
          title: 'SPAVe 8.0',
          subtitle:
              'Academic Research: Ways to Leverage Overall Impact',
          date: '6 Aug 2026',
          time: '2:00 PM',
          location: 'Multipurpose Hall, Annex-7',
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
        title: const Text(
          'Events',
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            GestureDetector(
              onTap: () => openSpave(context),
              child: _featuredEvent(),
            ),

            const SizedBox(height: 28),

            const Text(
              'Upcoming Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: () => openSpave(context),
              child: _eventCard(
                title: 'SPAVe 8.0',
                subtitle:
                    'Academic Research: Ways to Leverage Overall Impact',
                date: '6 Aug 2026',
                time: '2:00 PM',
                location: 'Multipurpose Hall, Annex-7',
                icon: Icons.science_rounded,
                accent: const Color(0xFF4D91FF),
              ),
            ),

            const SizedBox(height: 15),

            _eventCard(
              title: 'IEEE AIUB Volunteer Meet',
              subtitle:
                  'Volunteer coordination and team briefing',
              date: '12 Aug 2026',
              time: '4:00 PM',
              location: 'AIUB Campus',
              icon: Icons.groups_rounded,
              accent: const Color(0xFF7C8CFF),
            ),

            const SizedBox(height: 15),

            _eventCard(
              title: 'Tech Workshop',
              subtitle:
                  'Technology and career development session',
              date: '20 Aug 2026',
              time: '3:00 PM',
              location: 'AIUB Auditorium',
              icon: Icons.computer_rounded,
              accent: const Color(0xFF36D399),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredEvent() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D5BD7),
            Color(0xFF082E70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5BD7).withOpacity(0.30),
            blurRadius: 25,
            spreadRadius: 1,
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
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'UPCOMING EVENT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'FEATURED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 23),

          const Text(
            'SPAVe 8.0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Academic Research: Ways to Leverage Overall Impact',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              _infoChip(
                Icons.calendar_today_rounded,
                '6 Aug 2026',
              ),
              const SizedBox(width: 8),
              _infoChip(
                Icons.access_time_rounded,
                '2:00 PM',
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _infoChip(
                Icons.location_on_rounded,
                'Multipurpose Hall',
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'VIEW DETAILS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard({
    required String title,
    required String subtitle,
    required String date,
    required String time,
    required String location,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF091F40),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF173D72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          const Divider(
            color: Color(0xFF173D72),
            height: 1,
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _detail(
                  Icons.calendar_today_rounded,
                  date,
                  accent,
                ),
              ),
              Expanded(
                child: _detail(
                  Icons.access_time_rounded,
                  time,
                  accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _detail(
            Icons.location_on_rounded,
            location,
            accent,
          ),
        ],
      ),
    );
  }

  Widget _detail(
    IconData icon,
    String text,
    Color accent,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: accent,
          size: 15,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}