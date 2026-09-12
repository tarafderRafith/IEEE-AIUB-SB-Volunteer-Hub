import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
final String title;
final String subtitle;
final String date;
final String time;
final String location;

const EventDetailsScreen({
super.key,
required this.title,
required this.subtitle,
required this.date,
required this.time,
required this.location,
});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFF041329),
appBar: AppBar(
backgroundColor: const Color(0xFF041329),
elevation: 0,
iconTheme: const IconThemeData(
color: Colors.white,
),
title: const Text(
'Event Details',
style: TextStyle(
color: Colors.white,
fontSize: 21,
fontWeight: FontWeight.w800,
),
),
),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(26),
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
color: const Color(0xFF0D5BD7)
.withOpacity(0.3),
blurRadius: 25,
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 62,
height: 62,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.12),
borderRadius: BorderRadius.circular(18),
),
child: const Icon(
Icons.event_rounded,
color: Colors.white,
size: 32,
),
),
const SizedBox(height: 22),
Text(
title,
style: const TextStyle(
color: Colors.white,
fontSize: 28,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 10),
Text(
subtitle,
style: const TextStyle(
color: Colors.white70,
fontSize: 14,
height: 1.5,
),
),
],
),
),


          const SizedBox(height: 25),

          const Text(
            'Event Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          _infoCard(
            icon: Icons.calendar_month_rounded,
            title: 'Date',
            value: date,
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.access_time_rounded,
            title: 'Time',
            value: time,
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: location,
          ),

          const SizedBox(height: 28),

          const Text(
            'About This Event',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF091F40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF173D72),
              ),
            ),
            child: const Text(
              'SPAVe 8.0 is an academic research event organized '
              'to explore ways to leverage research for overall '
              'impact. Volunteers will support event coordination, '
              'registration, publicity and other assigned duties.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You are assigned to this event.',
                    ),
                    backgroundColor: Color(0xFF0D5BD7),
                  ),
                );
              },
              icon: const Icon(
                Icons.check_circle_outline_rounded,
              ),
              label: const Text(
                'VOLUNTEER ASSIGNED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5BD7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
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
padding: const EdgeInsets.all(17),
decoration: BoxDecoration(
color: const Color(0xFF091F40),
borderRadius: BorderRadius.circular(18),
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
color: const Color(0xFF0D5BD7).withOpacity(0.16),
borderRadius: BorderRadius.circular(14),
),
child: Icon(
icon,
color: const Color(0xFF4D91FF),
),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
color: Colors.white54,
fontSize: 12,
),
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
color: Colors.white,
fontSize: 15,
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
