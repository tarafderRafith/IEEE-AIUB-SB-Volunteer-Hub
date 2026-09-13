import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static const String _databaseName = 'ieee_volunteer_hub.db';
  static const int _databaseVersion = 3;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

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
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE users
        ADD COLUMN team TEXT NOT NULL DEFAULT 'Public Relations'
      ''');
    }

    if (oldVersion < 3) {
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

  // ============================================================
  // USER METHODS
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
          'executive_position': executivePosition,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
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

  static Future<Map<String, dynamic>?> getUserByMemberId(
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

  // ============================================================
  // VOLUNTEER METHODS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getVolunteers() async {
    final db = await database;

    return await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['Volunteer'],
      orderBy: 'full_name ASC',
    );
  }

  // ============================================================
  // TASK METHODS
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

    return await db.insert(
      'tasks',
      {
        'title': title,
        'description': description,
        'assigned_to_member_id': assignedToMemberId,
        'assigned_by_member_id': assignedByMemberId,
        'team': team,
        'priority': priority,
        'deadline': deadline,
        'status': 'Pending',
        'points': points,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getTasksForVolunteer(
    String memberId,
  ) async {
    final db = await database;

    return await db.query(
      'tasks',
      where: 'assigned_to_member_id = ?',
      whereArgs: [memberId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;

    return await db.query(
      'tasks',
      orderBy: 'created_at DESC',
    );
  }

  static Future<bool> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    final db = await database;

    final count = await db.update(
      'tasks',
      {
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );

    return count > 0;
  }

  static Future<bool> deleteTask(int taskId) async {
    final db = await database;

    final count = await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );

    return count > 0;
  }
}