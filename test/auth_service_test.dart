import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:consistency_builder/models/daily_task.dart';
import 'package:consistency_builder/services/auth_service.dart';
import 'package:consistency_builder/services/database_service.dart';
import 'package:consistency_builder/services/temporary_storage.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await DatabaseService.instance.database;
    await db.delete('users');
    await AuthService.instance.logout();
  });

  tearDown(() async {
    await AuthService.instance.logout();
    TemporaryStorage.instance.clear();
  });

  test('registers a username for a later login', () async {
    final user = await AuthService.instance.register(
      'alice123',
      'StrongPass!123',
    );

    expect(user, isNotNull);
    expect(await AuthService.instance.isLoggedIn(), isFalse);
    final loggedInUser = await AuthService.instance.login(
      'alice123',
      'StrongPass!123',
    );
    expect(loggedInUser, isNotNull);
    expect(await AuthService.instance.getCurrentUserId(), 'alice123');
  });

  test('accepts a password with exactly six characters', () async {
    final user = await AuthService.instance.register('sixchar', '123456');

    expect(user, isNotNull);
    expect(await AuthService.instance.login('sixchar', '123456'), isNotNull);
  });

  test('rejects passwords shorter than six characters', () async {
    final user = await AuthService.instance.register('shortpass', '12345');

    expect(user, isNull);
  });

  test('prevents duplicate usernames and rejects wrong passwords', () async {
    await AuthService.instance.register(
      'bob123',
      'StrongPass!123',
    );

    final duplicate = await AuthService.instance.register(
      'bob123',
      'AnotherPass!456',
    );
    expect(duplicate, isNull);

    final badLogin = await AuthService.instance.login(
      'bob123',
      'WrongPass!000',
    );
    expect(badLogin, isNull);

    final validLogin = await AuthService.instance.login(
      'bob123',
      'StrongPass!123',
    );
    expect(validLogin, isNotNull);
  });

  test('returns null for logins using a username that has no account', () async {
    final missingUser = await AuthService.instance.login(
      'missing123',
      'StrongPass!123',
    );

    expect(missingUser, isNull);
  });

  test('keeps task data separated for each username', () async {
    final firstUser = await AuthService.instance.register(
      'first123',
      'StrongPass!123',
    );
    final secondUser = await AuthService.instance.register(
      'second123',
      'StrongPass!123',
    );

    expect(firstUser, isNotNull);
    expect(secondUser, isNotNull);

    await TemporaryStorage.instance.initialize(userId: firstUser!.id);
    await TemporaryStorage.instance.addDailyTask(
      DailyTask(
        id: 'task-first',
        name: 'First account task',
        description: 'Only for first account',
        date: DateTime(2026, 8, 3),
        time: const TimeOfDay(hour: 9, minute: 0),
        taskType: TaskType.daily,
        isCompleted: false,
        createdDate: DateTime(2026, 8, 2),
        lastCompletedDate: null,
      ),
    );

    await TemporaryStorage.instance.initialize(userId: secondUser!.id);
    await TemporaryStorage.instance.addDailyTask(
      DailyTask(
        id: 'task-second',
        name: 'Second account task',
        description: 'Only for second account',
        date: DateTime(2026, 8, 3),
        time: const TimeOfDay(hour: 10, minute: 0),
        taskType: TaskType.daily,
        isCompleted: true,
        createdDate: DateTime(2026, 8, 2),
        lastCompletedDate: DateTime(2026, 8, 3),
      ),
    );

    await TemporaryStorage.instance.initialize(userId: firstUser.id);
    expect(TemporaryStorage.instance.dailyTasks, hasLength(1));
    expect(TemporaryStorage.instance.dailyTasks.first.id, 'task-first');

    await TemporaryStorage.instance.initialize(userId: secondUser.id);
    expect(TemporaryStorage.instance.dailyTasks, hasLength(1));
    expect(TemporaryStorage.instance.dailyTasks.first.id, 'task-second');
  });
}
