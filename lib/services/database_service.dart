import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/models/goal.dart';
import 'package:consistency_builder/models/user.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'consistency_builder.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='users'",
      );
      if (tableExists.isNotEmpty) {
        final existingColumns = await db.rawQuery('PRAGMA table_info(users)');
        final columns = existingColumns.map((column) => column['name'] as String).toSet();
        if (!columns.contains('passwordHash')) {
          await db.execute('ALTER TABLE users ADD COLUMN passwordHash TEXT');
        }
        if (!columns.contains('salt')) {
          await db.execute('ALTER TABLE users ADD COLUMN salt TEXT');
        }
      }
    }
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        passwordHash TEXT,
        salt TEXT
      )
    ''' );

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_users_name ON users(name)
    ''');

    await db.execute('''
      CREATE TABLE daily_tasks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        timeHour INTEGER NOT NULL,
        timeMinute INTEGER NOT NULL,
        taskType TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        createdDate TEXT NOT NULL,
        lastCompletedDate TEXT,
        reminderEnabled INTEGER NOT NULL,
        reminderDurationMinutes INTEGER,
        notificationId INTEGER,
        userId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        targetDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        createdDate TEXT NOT NULL,
        userId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_completion_history (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        userId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goal_completion_history (
        id TEXT PRIMARY KEY,
        goalId TEXT NOT NULL,
        completedAt TEXT NOT NULL,
        userId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminder_settings (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        reminderEnabled INTEGER NOT NULL,
        reminderDurationMinutes INTEGER,
        notificationId INTEGER,
        userId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE streak_information (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        currentStreak INTEGER NOT NULL,
        lastCheckDate TEXT NOT NULL
      )
    ''');
  }

  Future<AppUser> createUser(AppUser user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return user;
  }

  Future<AppUser?> getUser(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return AppUser.fromMap(maps.first);
  }

  Future<AppUser?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'LOWER(id) = ? OR LOWER(name) = ?',
      whereArgs: [username.toLowerCase(), username.toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return AppUser.fromMap(maps.first);
  }

  Future<List<DailyTask>> getDailyTasks({String? userId}) async {
    final db = await database;
    final maps = await db.query('daily_tasks', where: userId == null ? null : 'userId = ?', whereArgs: userId == null ? null : [userId]);
    return maps.map(DailyTask.fromMap).toList();
  }

  Future<void> insertDailyTask(DailyTask task, {String? userId}) async {
    final db = await database;
    await db.insert('daily_tasks', task.toMap(userId: userId), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDailyTask(DailyTask task, {String? userId}) async {
    final db = await database;
    await db.update('daily_tasks', task.toMap(userId: userId), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteDailyTask(String id) async {
    final db = await database;
    await db.delete('daily_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Goal>> getGoals({String? userId}) async {
    final db = await database;
    final maps = await db.query('goals', where: userId == null ? null : 'userId = ?', whereArgs: userId == null ? null : [userId]);
    return maps.map(Goal.fromMap).toList();
  }

  Future<void> insertGoal(Goal goal, {String? userId}) async {
    final db = await database;
    await db.insert('goals', goal.toMap(userId: userId), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateGoal(Goal goal, {String? userId}) async {
    final db = await database;
    await db.update('goals', goal.toMap(userId: userId), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertTaskCompletionHistory(String taskId, DateTime completedAt, String userId) async {
    final db = await database;
    await db.insert('task_completion_history', {
      'id': '${taskId}_${completedAt.millisecondsSinceEpoch}',
      'taskId': taskId,
      'completedAt': completedAt.toIso8601String(),
      'userId': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> getTaskCompletionHistory(String userId) async {
    final db = await database;
    return db.query('task_completion_history', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> deleteTaskCompletionHistory(String taskId, DateTime completedAt, String userId) async {
    final db = await database;
    await db.delete(
      'task_completion_history',
      where: 'taskId = ? AND completedAt = ? AND userId = ?',
      whereArgs: [taskId, completedAt.toIso8601String(), userId],
    );
  }

  Future<void> insertGoalCompletionHistory(String goalId, DateTime completedAt, String userId) async {
    final db = await database;
    await db.insert('goal_completion_history', {
      'id': '${goalId}_${completedAt.millisecondsSinceEpoch}',
      'goalId': goalId,
      'completedAt': completedAt.toIso8601String(),
      'userId': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> getGoalCompletionHistory(String userId) async {
    final db = await database;
    return db.query('goal_completion_history', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> saveReminderSettings(String taskId, bool reminderEnabled, Duration? reminderDuration, int? notificationId, String userId) async {
    final db = await database;
    await db.insert('reminder_settings', {
      'id': taskId,
      'taskId': taskId,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderDurationMinutes': reminderDuration?.inMinutes,
      'notificationId': notificationId,
      'userId': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>?> getReminderSettings(String taskId, String userId) async {
    final db = await database;
    final result = await db.query('reminder_settings', where: 'taskId = ? AND userId = ?', whereArgs: [taskId, userId], limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<void> saveStreakInformation(String userId, int currentStreak, DateTime lastCheckDate) async {
    final db = await database;
    await db.insert('streak_information', {
      'id': userId,
      'userId': userId,
      'currentStreak': currentStreak,
      'lastCheckDate': lastCheckDate.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>?> getStreakInformation(String userId) async {
    final db = await database;
    final result = await db.query('streak_information', where: 'userId = ?', whereArgs: [userId], limit: 1);
    return result.isEmpty ? null : result.first;
  }
}
