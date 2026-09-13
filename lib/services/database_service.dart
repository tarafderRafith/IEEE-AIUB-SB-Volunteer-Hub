import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static const String _databaseName =
      'ieee_volunteer_hub.db';

  static const int _databaseVersion = 6;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasePath =
        await getDatabasesPath();

    final path = join(
      databasePath,
      _databaseName,
    );

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(
    Database db,
    int version,
  ) async {
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

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        assigned_to_member_id TEXT NOT NULL,
        assigned_by_member_id TEXT NOT NULL,
        team TEXT NOT NULL,
        priority TEXT NOT NULL,
        deadline TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending',
        points INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        location TEXT NOT NULL,
        event_type TEXT NOT NULL,
        organizer TEXT NOT NULL,
        created_by_member_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<bool> _columnExists(
    Database db,
    String table,
    String column,
  ) async {
    final result = await db.rawQuery(
      'PRAGMA table_info($table)',
    );

    return result.any(
      (row) => row['name']?.toString() == column,
    );
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String columnDefinition,
    String columnName,
  ) async {
    final exists = await _columnExists(
      db,
      table,
      columnName,
    );

    if (!exists) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN $columnDefinition',
      );
    }
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(
        db,
        'users',
        "team TEXT NOT NULL DEFAULT 'Public Relations'",
        'team',
      );
    }

    if (oldVersion < 3) {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name = 'tasks'",
      );

      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            assigned_to_member_id TEXT NOT NULL,
            assigned_by_member_id TEXT NOT NULL,
            team TEXT NOT NULL,
            priority TEXT NOT NULL,
            deadline TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Pending',
            points INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
      }
    }

    if (oldVersion < 5) {
      await _addColumnIfMissing(
        db,
        'tasks',
        'started_at TEXT',
        'started_at',
      );

      await _addColumnIfMissing(
        db,
        'tasks',
        'completed_at TEXT',
        'completed_at',
      );

      await _addColumnIfMissing(
        db,
        'tasks',
        'updated_at TEXT',
        'updated_at',
      );

      await db.execute('''
        UPDATE tasks
        SET updated_at = created_at
        WHERE updated_at IS NULL
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          location TEXT NOT NULL,
          event_type TEXT NOT NULL,
          organizer TEXT NOT NULL,
          created_by_member_id TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ============================================================
  // USERS
  // ============================================================

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
    try {
      final db = await database;

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
          'executive_position':
              executivePosition,
        },
        conflictAlgorithm:
            ConflictAlgorithm.abort,
      );

      return true;
    } catch (e) {
      debugPrint(
        'Registration error: $e',
      );

      return false;
    }
  }

  static Future<bool> memberIdExists(
    String memberId,
  ) async {
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

  static Future<Map<String, dynamic>?>
      loginUser({
    required String memberId,
    required String password,
  }) async {
    final db = await database;

    final result = await db.query(
      'users',
      where:
          'member_id = ? AND password = ?',
      whereArgs: [
        memberId,
        password,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  static Future<Map<String, dynamic>?>
      getUserByMemberId(
    String memberId,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'member_id = ?',
      whereArgs: [memberId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  static Future<List<Map<String, dynamic>>>
      getVolunteers() async {
    final db = await database;

    return await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['Volunteer'],
      orderBy: 'full_name ASC',
    );
  }

  static Future<List<Map<String, dynamic>>>
      getExecutives() async {
    final db = await database;

    return await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['Executive'],
      orderBy: 'full_name ASC',
    );
  }

  // ============================================================
  // TASKS
  // ============================================================

  static Future<int> createTask({
    required String title,
    required String description,
    required String assignedToMemberId,
    required String assignedByMemberId,
    required String team,
    required String priority,
    required String deadline,
    required int points,
  }) async {
    final db = await database;

    final now =
        DateTime.now().toIso8601String();

    return await db.insert(
      'tasks',
      {
        'title': title,
        'description': description,
        'assigned_to_member_id':
            assignedToMemberId,
        'assigned_by_member_id':
            assignedByMemberId,
        'team': team,
        'priority': priority,
        'deadline': deadline,
        'status': 'Pending',
        'points': points,
        'created_at': now,
        'started_at': null,
        'completed_at': null,
        'updated_at': now,
      },
    );
  }

  static Future<List<Map<String, dynamic>>>
      getTasksForVolunteer(
    String memberId,
  ) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        tasks.*,

        executive.full_name
          AS assigned_by_name,

        executive.member_id
          AS assigned_by_member_id,

        executive.team
          AS assigned_by_team,

        executive.executive_position
          AS assigned_by_position

      FROM tasks

      LEFT JOIN users executive
        ON tasks.assigned_by_member_id =
           executive.member_id

      WHERE tasks.assigned_to_member_id = ?

      ORDER BY tasks.updated_at DESC
    ''', [
      memberId,
    ]);
  }

  static Future<List<Map<String, dynamic>>>
      getTasksAssignedByExecutive(
    String executiveMemberId,
  ) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        tasks.*,

        volunteer.full_name
          AS volunteer_name,

        volunteer.member_id
          AS volunteer_member_id,

        volunteer.team
          AS volunteer_team,

        volunteer.department
          AS volunteer_department

      FROM tasks

      LEFT JOIN users volunteer
        ON tasks.assigned_to_member_id =
           volunteer.member_id

      WHERE tasks.assigned_by_member_id = ?

      ORDER BY tasks.updated_at DESC
    ''', [
      executiveMemberId,
    ]);
  }

  static Future<List<Map<String, dynamic>>>
      getAllTasks() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT
        tasks.*,

        volunteer.full_name
          AS volunteer_name,

        volunteer.member_id
          AS volunteer_member_id,

        volunteer.team
          AS volunteer_team,

        executive.full_name
          AS assigned_by_name,

        executive.member_id
          AS assigned_by_member_id,

        executive.executive_position
          AS assigned_by_position,

        executive.team
          AS assigned_by_team

      FROM tasks

      LEFT JOIN users volunteer
        ON tasks.assigned_to_member_id =
           volunteer.member_id

      LEFT JOIN users executive
        ON tasks.assigned_by_member_id =
           executive.member_id

      ORDER BY tasks.updated_at DESC
    ''');
  }

  static Future<bool> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    final db = await database;

    final now =
        DateTime.now().toIso8601String();

    if (status != 'Pending' &&
        status != 'In Process' &&
        status != 'Done') {
      return false;
    }

    final existingTask =
        await db.query(
      'tasks',
      columns: [
        'id',
        'started_at',
        'completed_at',
      ],
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );

    if (existingTask.isEmpty) {
      return false;
    }

    final currentTask =
        existingTask.first;

    final Map<String, dynamic> values = {
      'status': status,
      'updated_at': now,
    };

    if (status == 'In Process') {
      final existingStartedAt =
          currentTask['started_at']
              ?.toString();

      if (existingStartedAt == null ||
          existingStartedAt.isEmpty) {
        values['started_at'] = now;
      }
    }

    if (status == 'Done') {
      final existingStartedAt =
          currentTask['started_at']
              ?.toString();

      if (existingStartedAt == null ||
          existingStartedAt.isEmpty) {
        values['started_at'] = now;
      }

      values['completed_at'] = now;
    }

    final count = await db.update(
      'tasks',
      values,
      where: 'id = ?',
      whereArgs: [taskId],
    );

    return count > 0;
  }

  static Future<bool> deleteTask(
    int taskId,
  ) async {
    final db = await database;

    final count = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );

    return count > 0;
  }

  // ============================================================
  // EVENTS
  // ============================================================

  static Future<int> createEvent({
    required String title,
    required String description,
    required String date,
    required String time,
    required String location,
    required String eventType,
    required String organizer,
    required String createdByMemberId,
  }) async {
    final db = await database;

    final now =
        DateTime.now().toIso8601String();

    return await db.insert(
      'events',
      {
        'title': title,
        'description': description,
        'date': date,
        'time': time,
        'location': location,
        'event_type': eventType,
        'organizer': organizer,
        'created_by_member_id':
            createdByMemberId,
        'created_at': now,
        'updated_at': now,
      },
    );
  }

  static Future<List<Map<String, dynamic>>>
      getAllEvents() async {
    final db = await database;

    return await db.query(
      'events',
      orderBy: 'date ASC, time ASC',
    );
  }

  static Future<Map<String, dynamic>?>
      getEventById(
    int eventId,
  ) async {
    final db = await database;

    final result = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  static Future<bool> deleteEvent(
    int eventId,
  ) async {
    final db = await database;

    final count = await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );

    return count > 0;
  }
}