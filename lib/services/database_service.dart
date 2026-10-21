import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/steam_models.dart';

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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        email TEXT NOT NULL,
        display_name TEXT,
        avatar_url TEXT,
        logged_in_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_game_state (
        steam_id TEXT NOT NULL,
        app_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Affectionless',
        start_date INTEGER,
        saved_playtime REAL NOT NULL DEFAULT 0.0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (steam_id, app_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_game_activity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        steam_id TEXT NOT NULL,
        app_id INTEGER NOT NULL,
        playtime_hours REAL NOT NULL,
        logged_at INTEGER NOT NULL,
        user_name TEXT,
        avatar_url TEXT
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
      version: 4,
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
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS active_session (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              email TEXT NOT NULL,
              display_name TEXT,
              avatar_url TEXT,
              logged_in_at INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_game_state (
              steam_id TEXT NOT NULL,
              app_id INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'Affectionless',
              start_date INTEGER,
              saved_playtime REAL NOT NULL DEFAULT 0.0,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (steam_id, app_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_game_activity (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              steam_id TEXT NOT NULL,
              app_id INTEGER NOT NULL,
              playtime_hours REAL NOT NULL,
              logged_at INTEGER NOT NULL,
              user_name TEXT,
              avatar_url TEXT
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
    await db.insert('user_profiles', {
      'email': email.trim().toLowerCase(),
      'display_name': displayName?.trim(),
      'steam_id': steamId.trim(),
      'avatar_url': avatarUrl?.trim(),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
    final results = await db.query('user_profiles', orderBy: 'updated_at DESC');
    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Import nhiều profile cùng lúc (dùng trong Backup & Restore)
  Future<int> importUserProfiles(List<Map<String, dynamic>> profiles) async {
    final db = await database;
    int importedCount = 0;
    await db.transaction((txn) async {
      for (final profile in profiles) {
        final email = (profile['email'] ?? '').toString().trim().toLowerCase();
        final steamId = (profile['steam_id'] ?? profile['steamId'] ?? '')
            .toString()
            .trim();
        if (email.isEmpty || steamId.isEmpty) continue;

        await txn.insert('user_profiles', {
          'email': email,
          'display_name': (profile['display_name'] ?? profile['displayName'])
              ?.toString()
              .trim(),
          'steam_id': steamId,
          'avatar_url': (profile['avatar_url'] ?? profile['avatarUrl'])
              ?.toString()
              .trim(),
          'updated_at': profile['updated_at'] is int
              ? profile['updated_at']
              : DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  /// Lưu phiên đăng nhập hiện tại vào SQLite (giúp tài khoản luôn được lưu trong app trừ khi logout hoặc xóa app)
  Future<void> saveActiveSession({
    required String email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final db = await database;
    await db.insert('active_session', {
      'id': 1,
      'email': email.trim().toLowerCase(),
      'display_name': displayName?.trim(),
      'avatar_url': avatarUrl?.trim(),
      'logged_in_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Lấy phiên đăng nhập đang hoạt động từ SQLite
  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await database;
    final results = await db.query('active_session', where: 'id = 1', limit: 1);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Xóa phiên đăng nhập (chỉ gọi khi người dùng chủ động nhấn Logout)
  Future<void> clearActiveSession() async {
    final db = await database;
    await db.delete('active_session', where: 'id = 1');
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
      final end = (i + chunkSize < appIds.length)
          ? i + chunkSize
          : appIds.length;
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
        if (appId == null || currencyCode == null || rawLowest == null) {
          continue;
        }

        final newLowest = (rawLowest as num).toDouble();
        final initialPrice = (record['initial_price'] as num?)?.toDouble();
        final finalPrice = (record['final_price'] as num?)?.toDouble();
        final discountPercent = (record['discount_percent'] as int?) ?? 0;
        final isFree = (record['is_free'] == true || record['is_free'] == 1)
            ? 1
            : 0;

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
          final oldLowest = (existing.first['lowest_price'] as num?)
              ?.toDouble();
          final oldInitial = (existing.first['initial_price'] as num?)
              ?.toDouble();

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

        await txn.insert('game_price_cache', {
          'app_id': appId,
          'currency_code': currencyCode,
          'initial_price': resolvedInitial,
          'final_price': finalPrice,
          'lowest_price': finalLowest,
          'discount_percent': discountPercent,
          'is_free': isFree,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Đảm bảo bảng user_game_state và user_game_activity đã được tạo
  Future<void> ensureGameUserTables() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_game_state (
        steam_id TEXT NOT NULL,
        app_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Affectionless',
        start_date INTEGER,
        saved_playtime REAL NOT NULL DEFAULT 0.0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (steam_id, app_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_game_activity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        steam_id TEXT NOT NULL,
        app_id INTEGER NOT NULL,
        playtime_hours REAL NOT NULL,
        logged_at INTEGER NOT NULL,
        user_name TEXT,
        avatar_url TEXT
      )
    ''');
  }

  /// Lưu trạng thái game (Affectionless, InProgress, Done) theo steam_id và app_id.
  /// Nếu chuyển sang 'InProgress', tự động gán start_date nếu chưa được cung cấp.
  Future<void> saveGameStatus({
    required String steamId,
    required int appId,
    required String status,
    DateTime? startDate,
  }) async {
    if (steamId.isEmpty) return;
    await ensureGameUserTables();
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await db.query(
      'user_game_state',
      where: 'steam_id = ? AND app_id = ?',
      whereArgs: [steamId, appId],
      limit: 1,
    );

    double savedPlaytime = 0.0;
    int? existingStartDate;
    if (existing.isNotEmpty) {
      savedPlaytime =
          (existing.first['saved_playtime'] as num?)?.toDouble() ?? 0.0;
      existingStartDate = existing.first['start_date'] as int?;
    }

    final finalStartDate = startDate != null
        ? startDate.millisecondsSinceEpoch
        : (status == 'InProgress' ? now : existingStartDate);

    await db.insert('user_game_state', {
      'steam_id': steamId,
      'app_id': appId,
      'status': status,
      'start_date': finalStartDate,
      'saved_playtime': savedPlaytime,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Lấy trạng thái game đã lưu theo steam_id và app_id
  Future<Map<String, dynamic>?> getGameStatus({
    required String steamId,
    required int appId,
  }) async {
    if (steamId.isEmpty) return null;
    await ensureGameUserTables();
    final db = await database;
    final results = await db.query(
      'user_game_state',
      where: 'steam_id = ? AND app_id = ?',
      whereArgs: [steamId, appId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Lấy toàn bộ trạng thái game theo steam_id
  Future<Map<int, Map<String, dynamic>>> getAllGameStates(
    String steamId,
  ) async {
    if (steamId.isEmpty) return {};
    await ensureGameUserTables();
    final db = await database;
    final results = await db.query(
      'user_game_state',
      where: 'steam_id = ?',
      whereArgs: [steamId],
    );
    final Map<int, Map<String, dynamic>> map = {};
    for (final row in results) {
      final appId = row['app_id'] as int?;
      if (appId != null) {
        map[appId] = Map<String, dynamic>.from(row);
      }
    }
    return map;
  }

  /// Thêm một mục activity mới
  Future<int> addGameActivity(GameActivity activity) async {
    await ensureGameUserTables();
    final db = await database;
    return await db.insert(
      'user_game_activity',
      activity.toMap()..remove('id'),
    );
  }

  /// Lấy danh sách activity của 1 game theo steam_id và app_id
  Future<List<GameActivity>> getGameActivities({
    required String steamId,
    required int appId,
  }) async {
    if (steamId.isEmpty) return [];
    await ensureGameUserTables();
    final db = await database;
    final results = await db.query(
      'user_game_activity',
      where: 'steam_id = ? AND app_id = ?',
      whereArgs: [steamId, appId],
      orderBy: 'logged_at DESC, id DESC',
    );
    return results.map((row) => GameActivity.fromMap(row)).toList();
  }

  /// Đồng bộ giờ chơi game theo steamId:
  /// Số giờ chơi mới trong activity = giờ mới đồng bộ TRỪ giờ lưu trong SQLite.
  /// Cập nhật game.status và game.startDate từ SQLite nếu đã lưu trước đó.
  Future<void> syncGamePlaytimes({
    required String steamId,
    required List<SteamGameItem> games,
    String? userName,
    String? avatarUrl,
  }) async {
    if (steamId.isEmpty || games.isEmpty) return;
    await ensureGameUserTables();
    final db = await database;
    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;

    final existingStates = await getAllGameStates(steamId);

    await db.transaction((txn) async {
      for (final game in games) {
        final existing = existingStates[game.appId];

        if (existing != null) {
          // 1. Phục hồi trạng thái và ngày bắt đầu đã lưu từ trước
          final savedStatus = existing['status'] as String?;
          if (savedStatus != null && savedStatus.isNotEmpty) {
            game.status = savedStatus;
          }
          final savedStartDateMillis = existing['start_date'] as int?;
          if (savedStartDateMillis != null) {
            game.startDate = DateTime.fromMillisecondsSinceEpoch(
              savedStartDateMillis,
            );
          }

          // 2. Tính số giờ mới chơi: delta = giờ mới đồng bộ - giờ đã lưu trong SQLite
          final savedPlaytime =
              (existing['saved_playtime'] as num?)?.toDouble() ?? 0.0;
          final delta = game.playtimeHours - savedPlaytime;

          if (delta > 0.01) {
            // Lưu activity với số giờ mới chơi delta
            await txn.insert('user_game_activity', {
              'steam_id': steamId,
              'app_id': game.appId,
              'playtime_hours': delta,
              'logged_at': nowMillis,
              'user_name': userName,
              'avatar_url': avatarUrl,
            });

            // Cập nhật số giờ đã lưu vào SQLite
            await txn.update(
              'user_game_state',
              {'saved_playtime': game.playtimeHours, 'updated_at': nowMillis},
              where: 'steam_id = ? AND app_id = ?',
              whereArgs: [steamId, game.appId],
            );
          }
        } else {
          // Game chưa từng được lưu trong SQLite cho steamId này
          // Lưu trạng thái ban đầu
          await txn.insert('user_game_state', {
            'steam_id': steamId,
            'app_id': game.appId,
            'status': game.status,
            'start_date': game.startDate?.millisecondsSinceEpoch,
            'saved_playtime': game.playtimeHours,
            'updated_at': nowMillis,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Nếu game đã có giờ chơi ban đầu (> 0), ghi nhận activity ban đầu
          if (game.playtimeHours > 0) {
            final loggedTime = game.lastPlayed != null
                ? game.lastPlayed!.millisecondsSinceEpoch
                : nowMillis;
            await txn.insert('user_game_activity', {
              'steam_id': steamId,
              'app_id': game.appId,
              'playtime_hours': game.playtimeHours,
              'logged_at': loggedTime,
              'user_name': userName,
              'avatar_url': avatarUrl,
            });
          }
        }
      }
    });
  }
}
