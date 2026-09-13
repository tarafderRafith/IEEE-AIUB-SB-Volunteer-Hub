import 'package:flutter/material.dart';

import '../services/database_service.dart';

class ExecutiveTaskDetailsScreen extends StatefulWidget {
final Map<String, dynamic> task;

const ExecutiveTaskDetailsScreen({
super.key,
required this.task,
});

@override
State<ExecutiveTaskDetailsScreen> createState() =>
_ExecutiveTaskDetailsScreenState();
}

class _ExecutiveTaskDetailsScreenState
extends State<ExecutiveTaskDetailsScreen> {
bool _isDeleting = false;

Map<String, dynamic> get task => widget.task;

String _value(
String key, [
String fallback = 'Not available',
]) {
final value = task[key]?.toString();


if (value == null || value.trim().isEmpty) {
  return fallback;
}

return value;


}

String _formatDateTime(String? value) {
if (value == null || value.trim().isEmpty) {
return 'Not available';
}


final date = DateTime.tryParse(value);

if (date == null) {
  return value;
}

final day =
    date.day.toString().padLeft(2, '0');

final month =
    date.month.toString().padLeft(2, '0');

final year = date.year.toString();

final hour =
    date.hour % 12 == 0 ? 12 : date.hour % 12;

final minute =
    date.minute.toString().padLeft(2, '0');

final period =
    date.hour >= 12 ? 'PM' : 'AM';

return '$day/$month/$year • '
    '$hour:$minute $period';


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

Color _priorityColor(String priority) {
switch (priority.toLowerCase()) {
case 'high':
return const Color(0xFFFF6B6B);


  case 'low':
    return const Color(0xFF55D88A);

  default:
    return const Color(0xFFFFB74D);
}


}

Future<void> _deleteTask() async {
final taskId = task['id'];


if (taskId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Unable to delete this task.',
      ),
      backgroundColor: Color(0xFFB3261E),
    ),
  );

  return;
}

final shouldDelete =
    await showDialog<bool>(
  context: context,
  builder: (context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A2348),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: const Text(
        'Delete Task?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: const Text(
        'This task will be permanently removed from the system. This action cannot be undone.',
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
              fontWeight: FontWeight.w700,
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

final success =
    await DatabaseService.deleteTask(
  int.tryParse(taskId.toString()) ?? -1,
);

if (!mounted) return;

setState(() {
  _isDeleting = false;
});

if (!success) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Failed to delete the task.',
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
'Untitled Task',
);


final description = _value(
  'description',
  'No description provided.',
);

final status = _value(
  'status',
  'Pending',
);

final priority = _value(
  'priority',
  'Medium',
);

final volunteerName = _value(
  'volunteer_name',
  'Unknown Volunteer',
);

final volunteerMemberId = _value(
  'volunteer_member_id',
  'Not available',
);

final volunteerTeam = _value(
  'volunteer_team',
  _value(
    'team',
    'Not assigned',
  ),
);

final volunteerDepartment = _value(
  'volunteer_department',
  'Not available',
);

final points = _value(
  'points',
  '0',
);

final deadline = _value(
  'deadline',
  'Not available',
);

final createdAt =
    task['created_at']?.toString();

final updatedAt =
    task['updated_at']?.toString();

final startedAt =
    task['started_at']?.toString();

final completedAt =
    task['completed_at']?.toString();

final statusColor =
    _statusColor(status);

final priorityColor =
    _priorityColor(priority);

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
      'Task Details',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    actions: [
      IconButton(
        onPressed:
            _isDeleting ? null : _deleteTask,
        icon: _isDeleting
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF6B6B),
                ),
              )
            : const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF6B6B),
              ),
      ),
      const SizedBox(width: 5),
    ],
  ),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        35,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildHero(
            title: title,
            status: status,
            statusColor: statusColor,
          ),

          const SizedBox(height: 18),

          _buildSectionTitle(
            'ASSIGNED VOLUNTEER',
          ),

          const SizedBox(height: 10),

          _buildVolunteerCard(
            name: volunteerName,
            memberId: volunteerMemberId,
            team: volunteerTeam,
            department:
                volunteerDepartment,
          ),

          const SizedBox(height: 22),

          _buildSectionTitle(
            'TASK INFORMATION',
          ),

          const SizedBox(height: 10),

          _buildInfoCard(
            children: [
              _infoRow(
                icon: Icons.description_outlined,
                title: 'Description',
                value: description,
                fullWidth: true,
              ),
              _divider(),
              _infoRow(
                icon: Icons.flag_outlined,
                title: 'Priority',
                value: priority,
                valueColor:
                    priorityColor,
              ),
              _divider(),
              _infoRow(
                icon:
                    Icons.workspace_premium_outlined,
                title: 'Points',
                value: '$points points',
                valueColor:
                    const Color(0xFFFFC857),
              ),
              _divider(),
              _infoRow(
                icon:
                    Icons.calendar_month_outlined,
                title: 'Deadline',
                value: deadline,
              ),
            ],
          ),

          const SizedBox(height: 22),

          _buildSectionTitle(
            'TASK TIMELINE',
          ),

          const SizedBox(height: 10),

          _buildTimelineCard(
            createdAt: createdAt,
            updatedAt: updatedAt,
            startedAt: startedAt,
            completedAt: completedAt,
            status: status,
          ),

          const SizedBox(height: 22),

          _buildStatusBanner(
            status: status,
            color: statusColor,
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF0A2348),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white10,
              ),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF4D91FF),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Task status is updated by the assigned volunteer. You can monitor the progress here or delete the task if it is no longer required.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
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

Widget _buildHero({
required String title,
required String status,
required Color statusColor,
}) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(21),
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
.withOpacity(0.20),
blurRadius: 25,
),
],
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Container(
width: 52,
height: 52,
decoration: BoxDecoration(
color:
Colors.white.withOpacity(0.10),
borderRadius:
BorderRadius.circular(16),
),
child: Icon(
_statusIcon(status),
color: Colors.white,
size: 27,
),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
color: Colors.white,
fontSize: 20,
fontWeight:
FontWeight.w800,
height: 1.2,
),
),
const SizedBox(height: 11),
Container(
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: statusColor
.withOpacity(0.15),
borderRadius:
BorderRadius.circular(9),
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
FontWeight.w800,
),
),
),
],
),
),
],
),
);
}

Widget _buildSectionTitle(
String title,
) {
return Text(
title,
style: const TextStyle(
color: Color(0xFF6EA6FF),
fontSize: 11,
fontWeight: FontWeight.w800,
letterSpacing: 1.4,
),
);
}

Widget _buildVolunteerCard({
required String name,
required String memberId,
required String team,
required String department,
}) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(17),
decoration: BoxDecoration(
color: const Color(0xFF0A2348),
borderRadius:
BorderRadius.circular(19),
border: Border.all(
color: Colors.white10,
),
),
child: Row(
children: [
Container(
width: 50,
height: 50,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: const Color(0xFF0D5BD7)
.withOpacity(0.18),
border: Border.all(
color: const Color(0xFF3D8BFF)
.withOpacity(0.25),
),
),
child: const Icon(
Icons.person_rounded,
color: Color(0xFF4D91FF),
size: 26,
),
),
const SizedBox(width: 13),
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
fontSize: 15,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 5),
Text(
memberId,
style: const TextStyle(
color: Color(0xFF6EA6FF),
fontSize: 11,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
'$team • $department',
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: const TextStyle(
color: Colors.white54,
fontSize: 10,
),
),
],
),
),
],
),
);
}

Widget _buildInfoCard({
required List<Widget> children,
}) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: const Color(0xFF0A2348),
borderRadius:
BorderRadius.circular(19),
border: Border.all(
color: Colors.white10,
),
),
child: Column(
children: children,
),
);
}

Widget _infoRow({
required IconData icon,
required String title,
required String value,
Color? valueColor,
bool fullWidth = false,
}) {
return Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Container(
width: 37,
height: 37,
decoration: BoxDecoration(
color: const Color(0xFF0D5BD7)
.withOpacity(0.12),
borderRadius:
BorderRadius.circular(11),
),
child: Icon(
icon,
color: const Color(0xFF4D91FF),
size: 19,
),
),
const SizedBox(width: 11),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
color: Colors.white38,
fontSize: 10,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
value,
style: TextStyle(
color:
valueColor ??
Colors.white,
fontSize: 12,
fontWeight: FontWeight.w600,
height: fullWidth
? 1.45
: 1.2,
),
),
],
),
),
],
);
}

Widget _divider() {
return Padding(
padding:
const EdgeInsets.symmetric(
vertical: 14,
),
child: Container(
height: 1,
color: Colors.white.withOpacity(0.06),
),
);
}

Widget _buildTimelineCard({
required String? createdAt,
required String? updatedAt,
required String? startedAt,
required String? completedAt,
required String status,
}) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(17),
decoration: BoxDecoration(
color: const Color(0xFF0A2348),
borderRadius:
BorderRadius.circular(19),
border: Border.all(
color: Colors.white10,
),
),
child: Column(
children: [
_timelineRow(
icon: Icons.add_circle_outline,
title: 'Created',
value:
_formatDateTime(createdAt),
color:
const Color(0xFF4D91FF),
isLast: false,
),
_timelineRow(
icon: Icons.update_rounded,
title: 'Last Updated',
value:
_formatDateTime(updatedAt),
color:
const Color(0xFF6EA6FF),
isLast: false,
),
if (startedAt != null &&
startedAt.isNotEmpty)
_timelineRow(
icon:
Icons.play_circle_outline,
title: 'Started',
value:
_formatDateTime(startedAt),
color:
const Color(0xFFFFB74D),
isLast:
completedAt == null ||
completedAt.isEmpty,
),
if (completedAt != null &&
completedAt.isNotEmpty)
_timelineRow(
icon:
Icons.check_circle_outline,
title: 'Completed',
value:
_formatDateTime(completedAt),
color:
const Color(0xFF55D88A),
isLast: true,
),
if ((startedAt == null ||
startedAt.isEmpty) &&
(completedAt == null ||
completedAt.isEmpty))
_timelineRow(
icon:
Icons.hourglass_empty_rounded,
title: 'Progress',
value: status,
color:
_statusColor(status),
isLast: true,
),
],
),
);
}

Widget _timelineRow({
required IconData icon,
required String title,
required String value,
required Color color,
required bool isLast,
}) {
return Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Column(
children: [
Container(
width: 34,
height: 34,
decoration: BoxDecoration(
color: color.withOpacity(0.12),
shape: BoxShape.circle,
),
child: Icon(
icon,
color: color,
size: 17,
),
),
if (!isLast)
Container(
width: 1,
height: 25,
color:
Colors.white.withOpacity(
0.08,
),
),
],
),
const SizedBox(width: 12),
Expanded(
child: Padding(
padding:
const EdgeInsets.only(
top: 2,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
color: Colors.white70,
fontSize: 11,
fontWeight:
FontWeight.w700,
),
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
color: Colors.white38,
fontSize: 10,
),
),
],
),
),
),
],
);
}

Widget _buildStatusBanner({
required String status,
required Color color,
}) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: color.withOpacity(0.08),
borderRadius:
BorderRadius.circular(17),
border: Border.all(
color: color.withOpacity(0.18),
),
),
child: Row(
children: [
Icon(
_statusIcon(status),
color: color,
size: 22,
),
const SizedBox(width: 11),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Current Status',
style: TextStyle(
color: color,
fontSize: 10,
fontWeight:
FontWeight.w700,
),
),
const SizedBox(height: 3),
Text(
status,
style: const TextStyle(
color: Colors.white,
fontSize: 14,
fontWeight:
FontWeight.w800,
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
