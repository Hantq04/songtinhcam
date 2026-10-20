import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
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

  /// Khởi tạo các bảng cơ sở dữ liệu
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        email TEXT PRIMARY KEY,
        display_name TEXT,
        steam_id TEXT,
        avatar_url TEXT,
        updated_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_price_cache (
        app_id INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        initial_price REAL,
        final_price REAL,
        lowest_price REAL NOT NULL,
        discount_percent INTEGER DEFAULT 0,
        is_free INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (app_id, currency_code)
      )
    ''');
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
      version: 2,
      onCreate: (db, version) async {
        await createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS game_price_cache (
              app_id INTEGER NOT NULL,
              currency_code TEXT NOT NULL,
              initial_price REAL,
              final_price REAL,
              lowest_price REAL NOT NULL,
              discount_percent INTEGER DEFAULT 0,
              is_free INTEGER DEFAULT 0,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (app_id, currency_code)
            )
          ''');
        }
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

  /// Lấy toàn bộ danh sách profiles đã lưu
  Future<List<Map<String, dynamic>>> getAllUserProfiles() async {
    final db = await database;
    final results = await db.query(
      'user_profiles',
      orderBy: 'updated_at DESC',
    );
    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Import nhiều profile cùng lúc (dùng trong Backup & Restore)
  Future<int> importUserProfiles(List<Map<String, dynamic>> profiles) async {
    final db = await database;
    int importedCount = 0;
    await db.transaction((txn) async {
      for (final profile in profiles) {
        final email = (profile['email'] ?? '').toString().trim().toLowerCase();
        final steamId = (profile['steam_id'] ?? profile['steamId'] ?? '').toString().trim();
        if (email.isEmpty || steamId.isEmpty) continue;

        await txn.insert(
          'user_profiles',
          {
            'email': email,
            'display_name': (profile['display_name'] ?? profile['displayName'])?.toString().trim(),
            'steam_id': steamId,
            'avatar_url': (profile['avatar_url'] ?? profile['avatarUrl'])?.toString().trim(),
            'updated_at': profile['updated_at'] is int
                ? profile['updated_at']
                : DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        importedCount++;
      }
    });
    return importedCount;
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

  /// Đảm bảo bảng game_price_cache đã được tạo (an toàn khi chạy test in-memory hoặc migration cũ)
  Future<void> ensureGamePriceCacheTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_price_cache (
        app_id INTEGER NOT NULL,
        currency_code TEXT NOT NULL,
        initial_price REAL,
        final_price REAL,
        lowest_price REAL NOT NULL,
        discount_percent INTEGER DEFAULT 0,
        is_free INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (app_id, currency_code)
      )
    ''');
  }

  /// Lấy thông tin giá cache của một danh sách appIds theo loại tiền tệ (VND / USD)
  Future<Map<int, Map<String, dynamic>>> getCachedGamePrices({
    required List<int> appIds,
    required String currencyCode,
  }) async {
    if (appIds.isEmpty) return {};
    await ensureGamePriceCacheTable();
    final db = await database;

    final Map<int, Map<String, dynamic>> results = {};
    const chunkSize = 500;
    for (int i = 0; i < appIds.length; i += chunkSize) {
      final end =
          (i + chunkSize < appIds.length) ? i + chunkSize : appIds.length;
      final chunk = appIds.sublist(i, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.query(
        'game_price_cache',
        where: 'currency_code = ? AND app_id IN ($placeholders)',
        whereArgs: [currencyCode, ...chunk],
      );
      for (final row in rows) {
        final appId = row['app_id'] as int?;
        if (appId != null) {
          results[appId] = Map<String, dynamic>.from(row);
        }
      }
    }
    return results;
  }

  /// Lưu hoặc cập nhật thông tin giá của danh sách game vào SQLite.
  /// QUAN TRỌNG: lowest_price (giá đáy lịch sử) TUYỆT ĐỐI KHÔNG TĂNG LÊN.
  /// Nó chỉ giữ nguyên hoặc giảm xuống nếu phát hiện mức giá thấp hơn.
  Future<void> saveGamePrices(List<Map<String, dynamic>> priceRecords) async {
    if (priceRecords.isEmpty) return;
    await ensureGamePriceCacheTable();
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final record in priceRecords) {
        final appId = record['app_id'] as int?;
        final currencyCode = record['currency_code']?.toString();
        final rawLowest = record['lowest_price'];
        if (appId == null || currencyCode == null || rawLowest == null) continue;

        final newLowest = (rawLowest as num).toDouble();
        final initialPrice = (record['initial_price'] as num?)?.toDouble();
        final finalPrice = (record['final_price'] as num?)?.toDouble();
        final discountPercent = (record['discount_percent'] as int?) ?? 0;
        final isFree =
            (record['is_free'] == true || record['is_free'] == 1) ? 1 : 0;

        // Kiểm tra xem đã có bản ghi trong SQLite chưa
        final existing = await txn.query(
          'game_price_cache',
          columns: ['lowest_price', 'initial_price'],
          where: 'app_id = ? AND currency_code = ?',
          whereArgs: [appId, currencyCode],
          limit: 1,
        );

        double finalLowest = newLowest;
        double? resolvedInitial = initialPrice;

        if (existing.isNotEmpty) {
          final oldLowest = (existing.first['lowest_price'] as num?)?.toDouble();
          final oldInitial =
              (existing.first['initial_price'] as num?)?.toDouble();

          if (resolvedInitial == null || resolvedInitial == 0) {
            resolvedInitial = oldInitial;
          }

          if (isFree == 1) {
            finalLowest = 0;
          } else if (oldLowest != null && oldLowest > 0) {
            // Nếu đã từng có giá đáy hợp lệ: không cho phép giá tăng lên
            if (finalLowest <= 0 || oldLowest < finalLowest) {
              finalLowest = oldLowest;
            }
          }
        }

        await txn.insert(
          'game_price_cache',
          {
            'app_id': appId,
            'currency_code': currencyCode,
            'initial_price': resolvedInitial,
            'final_price': finalPrice,
            'lowest_price': finalLowest,
            'discount_percent': discountPercent,
            'is_free': isFree,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
