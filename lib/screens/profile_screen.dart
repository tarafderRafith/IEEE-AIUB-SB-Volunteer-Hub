import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
const ProfileScreen({super.key});

@override
State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
Map<String, dynamic>? _user;

List<Map<String, dynamic>> _tasks = [];

bool _isLoading = true;

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
final memberId = AuthService.memberId?.trim();


if (memberId == null || memberId.isEmpty) {
  if (!mounted) return;

  setState(() {
    _isLoading = false;
    _user = null;
    _tasks = [];
  });

  return;
}

try {
  final results = await Future.wait([
    DatabaseService.getUserByMemberId(memberId),
    DatabaseService.getTasksForVolunteer(memberId),
  ]);

  if (!mounted) return;

  setState(() {
    _user = results[0] as Map<String, dynamic>?;
    _tasks = results[1] as List<Map<String, dynamic>>;
    _isLoading = false;
  });

  debugPrint('👤 Profile loaded for member: $memberId');
} catch (e) {
  debugPrint('❌ Failed to load profile: $e');

  if (!mounted) return;

  setState(() {
    _isLoading = false;
  });
}


}

Future<void> _openEditProfile() async {
final updated = await Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const EditProfileScreen(),
),
);


if (!mounted) return;

if (updated == true) {
  setState(() {
    _isLoading = true;
  });

  await _loadProfile();
}


}

String _value(String key, String fallback) {
final value = _user?[key]?.toString().trim();


if (value == null || value.isEmpty) {
  return fallback;
}

return value;


}

String get _fullName {
return _value('full_name', AuthService.fullName ?? 'Volunteer');
}

String get _memberId {
return _value('member_id', AuthService.memberId ?? 'N/A');
}

String get _email {
return _value('email', AuthService.email ?? 'Not available');
}

String get _phone {
return _value('phone', AuthService.phone ?? 'Not available');
}

String get _department {
return _value(
'department',
AuthService.department ?? 'Not available',
);
}

String get _team {
return _value(
'team',
AuthService.team ?? 'Not available',
);
}

String get _role {
return _value(
'role',
AuthService.role ?? 'Volunteer',
);
}

String get _executivePosition {
return _value(
'executive_position',
AuthService.executivePosition ?? '',
);
}

int get _totalTasks {
return _tasks.length;
}

int get _completedTasks {
return _tasks.where((task) {
return task['status']?.toString() == 'Done';
}).length;
}

int get _pendingTasks {
return _tasks.where((task) {
return task['status']?.toString() == 'Pending';
}).length;
}

int get _inProcessTasks {
return _tasks.where((task) {
return task['status']?.toString() == 'In Process';
}).length;
}

int get _points {
int total = 0;


for (final task in _tasks) {
  if (task['status']?.toString() != 'Done') {
    continue;
  }

  final points = int.tryParse(
    task['points']?.toString() ?? '0',
  );

  total += points ?? 0;
}

return total;


}

String get _initial {
if (_fullName.isEmpty) {
return 'V';
}


return _fullName[0].toUpperCase();


}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFF06152E),
appBar: AppBar(
backgroundColor: const Color(0xFF06152E),
elevation: 0,
centerTitle: false,
leading: IconButton(
icon: const Icon(
Icons.arrow_back_ios_new_rounded,
color: Colors.white,
size: 20,
),
onPressed: () {
Navigator.pop(context);
},
),
title: const Text(
'Profile',
style: TextStyle(
color: Colors.white,
fontSize: 19,
fontWeight: FontWeight.w800,
),
),
actions: [
IconButton(
onPressed: _openEditProfile,
tooltip: 'Edit Profile',
icon: const Icon(
Icons.edit_rounded,
color: Color(0xFF6EB3FF),
),
),
IconButton(
onPressed: _loadProfile,
tooltip: 'Refresh',
icon: const Icon(
Icons.refresh_rounded,
color: Color(0xFF6EB3FF),
),
),
const SizedBox(width: 5),
],
),
body: _isLoading
? const Center(
child: CircularProgressIndicator(
color: Color(0xFF2388FF),
strokeWidth: 2.5,
),
)
: RefreshIndicator(
color: const Color(0xFF2388FF),
backgroundColor: const Color(0xFF0B2244),
onRefresh: _loadProfile,
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.fromLTRB(
18,
10,
18,
30,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_buildProfileHeader(),


                const SizedBox(height: 20),

                _buildStatistics(),

                const SizedBox(height: 22),

                const Text(
                  'Personal Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 11),

                _buildInformationCard(),

                const SizedBox(height: 22),

                _buildMembershipCard(),
              ],
            ),
          ),
        ),
);


}

Widget _buildProfileHeader() {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(22),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(24),
gradient: const LinearGradient(
colors: [
Color(0xFF0D3B78),
Color(0xFF092850),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
border: Border.all(
color: const Color(0xFF1B5CA8),
width: 1,
),
boxShadow: [
BoxShadow(
color: const Color(0xFF0D6EFD).withOpacity(0.12),
blurRadius: 20,
spreadRadius: 1,
),
],
),
child: Column(
children: [
Container(
width: 82,
height: 82,
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
color: const Color(0xFF62AFFF),
width: 2,
),
boxShadow: [
BoxShadow(
color: const Color(0xFF0D6EFD).withOpacity(0.30),
blurRadius: 20,
spreadRadius: 2,
),
],
),
child: Center(
child: Text(
_initial,
style: const TextStyle(
color: Colors.white,
fontSize: 32,
fontWeight: FontWeight.w900,
),
),
),
),


      const SizedBox(height: 14),

      Text(
        _fullName,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),

      const SizedBox(height: 5),

      Text(
        'Member ID: $_memberId',
        style: const TextStyle(
          color: Color(0xFF86B9EC),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 12),

      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D6EFD).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF328EFF).withOpacity(0.35),
          ),
        ),
        child: Text(
          _role,
          style: const TextStyle(
            color: Color(0xFF6EB3FF),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  ),
);


}

Widget _buildStatistics() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'My Activity',
style: TextStyle(
color: Colors.white,
fontSize: 17,
fontWeight: FontWeight.w800,
),
),


    const SizedBox(height: 11),

    Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.task_alt_rounded,
            title: 'Total',
            value: _totalTasks.toString(),
            color: const Color(0xFF3D9BFF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            title: 'Done',
            value: _completedTasks.toString(),
            color: const Color(0xFF36D399),
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.pending_actions_rounded,
            title: 'Pending',
            value: _pendingTasks.toString(),
            color: const Color(0xFFFBBF24),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.sync_rounded,
            title: 'In Process',
            value: _inProcessTasks.toString(),
            color: const Color(0xFF38BDF8),
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2244),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF153A69),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Color(0xFFFBBF24),
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earned Points',
                  style: TextStyle(
                    color: Color(0xFF829DBA),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Points from completed tasks',
                  style: TextStyle(
                    color: Color(0xFFB7CBE2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _points.toString(),
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  ],
);


}

Widget _buildStatCard({
required IconData icon,
required String title,
required String value,
required Color color,
}) {
return Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: const Color(0xFF0B2244),
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: const Color(0xFF153A69),
),
),
child: Row(
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: color.withOpacity(0.12),
borderRadius: BorderRadius.circular(11),
),
child: Icon(
icon,
color: color,
size: 19,
),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
color: Color(0xFF829DBA),
fontSize: 10,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 2),
Text(
value,
style: const TextStyle(
color: Colors.white,
fontSize: 19,
fontWeight: FontWeight.w900,
),
),
],
),
),
],
),
);
}

Widget _buildInformationCard() {
return Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 5,
),
decoration: BoxDecoration(
color: const Color(0xFF0B2244),
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: const Color(0xFF153A69),
),
),
child: Column(
children: [
_buildInfoRow(
icon: Icons.badge_outlined,
label: 'Member ID',
value: _memberId,
),
_buildDivider(),


      _buildInfoRow(
        icon: Icons.email_outlined,
        label: 'Email',
        value: _email,
      ),
      _buildDivider(),

      _buildInfoRow(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: _phone,
      ),
      _buildDivider(),

      _buildInfoRow(
        icon: Icons.school_outlined,
        label: 'Department',
        value: _department,
      ),
      _buildDivider(),

      _buildInfoRow(
        icon: Icons.groups_outlined,
        label: 'Team',
        value: _team,
      ),
    ],
  ),
);


}

Widget _buildMembershipCard() {
final hasExecutivePosition =
_executivePosition.isNotEmpty &&
_executivePosition.toLowerCase() != 'null';


return Container(
  width: double.infinity,
  padding: const EdgeInsets.all(17),
  decoration: BoxDecoration(
    color: const Color(0xFF0B2244),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color(0xFF153A69),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Membership',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),

      const SizedBox(height: 14),

      _buildMembershipItem(
        icon: Icons.person_outline_rounded,
        label: 'Role',
        value: _role,
      ),

      if (hasExecutivePosition) ...[
        const SizedBox(height: 12),
        _buildMembershipItem(
          icon: Icons.workspace_premium_outlined,
          label: 'Executive Position',
          value: _executivePosition,
        ),
      ],

      const SizedBox(height: 12),

      _buildMembershipItem(
        icon: Icons.groups_rounded,
        label: 'Team',
        value: _team,
      ),
    ],
  ),
);


}

Widget _buildMembershipItem({
required IconData icon,
required String label,
required String value,
}) {
return Row(
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: const Color(0xFF2388FF).withOpacity(0.10),
borderRadius: BorderRadius.circular(11),
),
child: Icon(
icon,
color: const Color(0xFF5EA9FF),
size: 19,
),
),
const SizedBox(width: 11),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
color: Color(0xFF738EAE),
fontSize: 10,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 2),
Text(
value,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: Color(0xFFD7E5F4),
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
],
),
),
],
);
}

Widget _buildInfoRow({
required IconData icon,
required String label,
required String value,
}) {
return Padding(
padding: const EdgeInsets.symmetric(
vertical: 14,
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: const Color(0xFF2388FF).withOpacity(0.10),
borderRadius: BorderRadius.circular(11),
),
child: Icon(
icon,
color: const Color(0xFF5EA9FF),
size: 19,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(
color: Color(0xFF738EAE),
fontSize: 10,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 3),
Text(
value,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: Color(0xFFD7E5F4),
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
],
),
),
],
),
);
}

Widget _buildDivider() {
return const Divider(
height: 1,
thickness: 1,
color: Color(0xFF153A69),
);
}
}
