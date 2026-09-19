import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:consistency_builder/models/user.dart';
import 'package:consistency_builder/services/database_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _loggedInUserKey = 'logged_in_user_id';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getCurrentUserId() async {
    await initialize();
    return _prefs!.getString(_loggedInUserKey);
  }

  Future<AppUser?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return DatabaseService.instance.getUser(userId);
  }

  Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }

  Future<bool> isUsernameAvailable(String username) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      return false;
    }
    final existingUser = await DatabaseService.instance.getUserByUsername(normalizedUsername);
    return existingUser == null;
  }

  Future<AppUser?> login(String username, String password) async {
    try {
      final trimmedUsername = username.trim();
      final normalizedUsername = trimmedUsername.toLowerCase();
      if (normalizedUsername.isEmpty || password.isEmpty) {
        return null;
      }

      final existingUser = await DatabaseService.instance.getUserByUsername(normalizedUsername);
      if (existingUser == null) {
        return null;
      }

      final salt = existingUser.salt ?? '';
      final suppliedHash = _hashPassword(password, salt);
      if (suppliedHash != existingUser.passwordHash) {
        return null;
      }

      await _storeLoggedInUser(existingUser.id);
      return existingUser;
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> register(String username, String password) async {
    try {
      final trimmedUsername = username.trim();
      final normalizedUsername = trimmedUsername.toLowerCase();
      if (normalizedUsername.isEmpty) {
        return null;
      }

      if (password.length < 6) {
        return null;
      }

      final existingUser = await DatabaseService.instance.getUserByUsername(normalizedUsername);
      if (existingUser != null) {
        return null;
      }

      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);
      final now = DateTime.now();
      final user = AppUser(
        id: normalizedUsername,
        name: normalizedUsername,
        createdAt: now,
        passwordHash: passwordHash,
        salt: salt,
      );

      await DatabaseService.instance.createUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await initialize();
    await _prefs!.remove(_loggedInUserKey);
  }

  String _generateSalt() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _storeLoggedInUser(String userId) async {
    await initialize();
    await _prefs!.setString(_loggedInUserKey, userId);
  }
}
