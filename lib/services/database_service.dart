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
  version: 1,
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
        executive_position TEXT
      )
    ''');
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
  return null;
}

return result.first;


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
}
