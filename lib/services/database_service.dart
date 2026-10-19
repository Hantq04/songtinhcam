import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Service quản lý cơ sở dữ liệu SQLite cục bộ (không dùng DB bên ngoài)
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;
  static bool _ffiInitialized = false;

  /// Khởi tạo database
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Với Desktop (Windows, Linux, macOS) và môi trường unit test:
    // Khởi tạo sqflite_common_ffi 1 lần duy nhất
    if (!_ffiInitialized &&
        !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'songtinhcam_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_profiles (
            email TEXT PRIMARY KEY,
            display_name TEXT,
            steam_id TEXT,
            avatar_url TEXT,
            updated_at INTEGER
          )
        ''');
      },
    );
  }

  /// Cho phép thiết lập Database trực tiếp (phục vụ unit test in-memory)
  @visibleForTesting
  void setDatabaseForTesting(Database? db) {
    _db = db;
  }

  /// Lưu hoặc cập nhật thông tin user và Steam ID theo Email
  Future<void> saveUserProfile({
    required String email,
    String? displayName,
    required String steamId,
    String? avatarUrl,
  }) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      {
        'email': email.trim().toLowerCase(),
        'display_name': displayName?.trim(),
        'steam_id': steamId.trim(),
        'avatar_url': avatarUrl?.trim(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy thông tin user profile theo Email
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    final db = await database;
    final normalized = email.trim().toLowerCase();
    final results = await db.query(
      'user_profiles',
      where: 'email = ?',
      whereArgs: [normalized],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Lấy riêng Steam ID đã lưu theo Email
  Future<String?> getSavedSteamId(String email) async {
    final profile = await getUserProfile(email);
    if (profile != null) {
      final steamId = profile['steam_id'] as String?;
      if (steamId != null && steamId.trim().isNotEmpty) {
        return steamId.trim();
      }
    }
    return null;
  }

  /// Xóa profile nếu cần
  Future<void> deleteUserProfile(String email) async {
    final db = await database;
    await db.delete(
      'user_profiles',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }
}
