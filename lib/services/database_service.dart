import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
static Database? _database;

static Future<Database> get database async {
if (_database != null) {
return _database!;
}


_database = await _initializeDatabase();
return _database!;


}

static Future<Database> _initializeDatabase() async {
final databasePath = await getDatabasesPath();
final path = join(databasePath, 'ieee_volunteer_hub.db');


return await openDatabase(
  path,
  version: 2,
  onCreate: (db, version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        member_id TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        department TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        team TEXT NOT NULL,
        executive_position TEXT
      )
    ''');
  },
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN team TEXT NOT NULL DEFAULT 'Public Relations'",
      );
    }
  },
);


}

static Future<bool> registerUser({
required String fullName,
required String memberId,
required String email,
required String phone,
required String department,
required String password,
required String role,
required String team,
String? executivePosition,
}) async {
final db = await database;


try {
  await db.insert(
    'users',
    {
      'full_name': fullName,
      'member_id': memberId,
      'email': email,
      'phone': phone,
      'department': department,
      'password': password,
      'role': role,
      'team': team,
      'executive_position': executivePosition,
    },
    conflictAlgorithm: ConflictAlgorithm.abort,
  );

  return true;
} catch (_) {
  return false;
}


}

static Future<Map<String, dynamic>?> loginUser({
required String memberId,
required String password,
}) async {
final db = await database;


final result = await db.query(
  'users',
  where: 'member_id = ? AND password = ?',
  whereArgs: [memberId, password],
  limit: 1,
);

if (result.isEmpty) {
  debugPrintUsers(
    message: 'LOGIN FAILED - No matching user found',
    memberId: memberId,
  );

  return null;
}

final user = result.first;

debugPrintUsers(
  message: 'LOGIN SUCCESS - Database returned this user',
  memberId: memberId,
  specificUser: user,
);

return user;


}

static Future<bool> memberIdExists(String memberId) async {
final db = await database;


final result = await db.query(
  'users',
  columns: ['id'],
  where: 'member_id = ?',
  whereArgs: [memberId],
  limit: 1,
);

return result.isNotEmpty;


}

// ------------------------------------------------------------
// SAFE DEBUG METHOD
// ------------------------------------------------------------
//
// This method ONLY READS the users table.
//
// It does NOT:
// - create users
// - edit users
// - delete users
// - change passwords
// - change names
//
// It prints the currently stored accounts to the Flutter console.
//
static Future<void> debugPrintUsers({
String message = 'DATABASE DEBUG',
String? memberId,
Map<String, dynamic>? specificUser,
}) async {
final db = await database;


print('');
print('==================================================');
print('IEEE VOLUNTEER HUB - DATABASE DEBUG');
print('==================================================');
print(message);
print('--------------------------------------------------');

if (specificUser != null) {
  print('LOGIN RESULT:');
  print('Database ID       : ${specificUser['id']}');
  print('Full Name         : ${specificUser['full_name']}');
  print('Member ID         : ${specificUser['member_id']}');
  print('Email             : ${specificUser['email']}');
  print('Phone             : ${specificUser['phone']}');
  print('Department        : ${specificUser['department']}');
  print('Role              : ${specificUser['role']}');
  print('Team              : ${specificUser['team']}');
  print('Executive Position: ${specificUser['executive_position']}');
  print('--------------------------------------------------');
}

final List<Map<String, dynamic>> users = await db.query(
  'users',
  orderBy: 'id ASC',
);

print('TOTAL USERS IN LOCAL DATABASE: ${users.length}');
print('');

if (users.isEmpty) {
  print('NO USERS FOUND IN DATABASE.');
} else {
  for (final user in users) {
    print(
      'ID: ${user['id']} | '
      'Member ID: ${user['member_id']} | '
      'Name: ${user['full_name']} | '
      'Role: ${user['role']} | '
      'Team: ${user['team']}',
    );
  }
}

if (memberId != null) {
  print('');
  print('SEARCHED MEMBER ID: $memberId');

  final matchingUsers = users.where(
    (user) => user['member_id'] == memberId,
  );

  if (matchingUsers.isEmpty) {
    print('RESULT: Member ID was NOT found in the database.');
  } else {
    print('RESULT: Member ID exists in the database.');
  }
}

print('==================================================');
print('');


}
}
