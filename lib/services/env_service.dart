import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Service tập trung quản lý việc phân giải đường dẫn và tải các biến môi trường từ .env
class EnvService {
  static final Map<String, String> _cache = {};
  static bool _assetLoaded = false;

  /// Các đường dẫn ứng viên để quét file .env (phục vụ môi trường Desktop, CLI, Unit tests)
  static const List<String> candidatePaths = [
    '.env',
    '../.env',
    '../../.env',
    '../../../.env',
    '../../../../.env',
  ];

  /// Lấy giá trị biến môi trường bất đồng bộ theo [key].
  /// Thứ tự quét:
  /// 1. Bộ nhớ đệm (Cache)
  /// 2. Biến hệ thống Platform.environment (--dart-define / OS env)
  /// 3. File vật lý .env tại các candidatePaths
  /// 4. Asset bundle .env của Flutter app (khi chạy trên Android/iOS thật hoặc máy ảo)
  static Future<String?> get(String key) async {
    if (_cache.containsKey(key) && _cache[key]!.isNotEmpty) {
      return _cache[key];
    }

    // 1. Kiểm tra biến môi trường hệ thống
    if (!kIsWeb) {
      try {
        final envVal = Platform.environment[key];
        if (envVal != null && envVal.trim().isNotEmpty) {
          _cache[key] = envVal.trim();
          return _cache[key];
        }
      } catch (_) {}
    }

    // 2. Thử đọc từ file hệ thống trước
    _loadFromLocalFiles();
    if (_cache.containsKey(key) && _cache[key]!.isNotEmpty) {
      return _cache[key];
    }

    // 3. Đọc từ asset bundle Flutter
    await _loadFromAssetBundle();
    return _cache[key];
  }

  /// Lấy giá trị biến môi trường đồng bộ (dùng cho các getter không hỗ trợ async)
  static String? getSync(String key) {
    if (_cache.containsKey(key) && _cache[key]!.isNotEmpty) {
      return _cache[key];
    }

    if (!kIsWeb) {
      try {
        final envVal = Platform.environment[key];
        if (envVal != null && envVal.trim().isNotEmpty) {
          _cache[key] = envVal.trim();
          return _cache[key];
        }
      } catch (_) {}
    }

    _loadFromLocalFiles();
    return _cache[key];
  }

  /// Steam Web API Key
  static Future<String> getSteamApiKey() async {
    const dartDefineKey = String.fromEnvironment('STEAM_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    return (await get('STEAM_API_KEY')) ?? '';
  }

  /// Getter đồng bộ cho Steam Web API Key
  static String get defaultSteamApiKey {
    const dartDefineKey = String.fromEnvironment('STEAM_API_KEY');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    return getSync('STEAM_API_KEY') ?? '';
  }

  /// Google OAuth Client ID
  static Future<String?> getGoogleClientId() async {
    const dartDefineKey = String.fromEnvironment('GOOGLE_CLIENT_ID');
    if (dartDefineKey.isNotEmpty) return dartDefineKey;
    return await get('GOOGLE_CLIENT_ID');
  }

  /// Đọc và phân giải từ các đường dẫn file .env nội bộ
  static void _loadFromLocalFiles() {
    try {
      for (final path in candidatePaths) {
        final envFile = File(path);
        if (envFile.existsSync()) {
          final lines = envFile.readAsLinesSync();
          _parseLines(lines);
          if (_cache.isNotEmpty) {
            return;
          }
        }
      }
    } catch (_) {}
  }

  /// Đọc từ rootBundle asset .env (Android / iOS / Web)
  static Future<void> _loadFromAssetBundle() async {
    if (_assetLoaded) return;
    try {
      final content = await rootBundle.loadString('.env');
      final lines = content.split('\n');
      _parseLines(lines);
      _assetLoaded = true;
    } catch (_) {}
  }

  /// Phân tích cú pháp các dòng trong file .env
  static void _parseLines(List<String> lines) {
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        final key = trimmed.substring(0, eqIdx).trim();
        var val = trimmed.substring(eqIdx + 1).trim();

        // Xóa dấu nháy kép hoặc đơn bọc quanh giá trị nếu có
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }

        if (key.isNotEmpty) {
          _cache[key] = val;
        }
      }
    }
  }

  /// Thiết lập giá trị tạm thời phục vụ unit test
  @visibleForTesting
  static void setForTesting(String key, String value) {
    _cache[key] = value;
  }

  /// Xóa cache phục vụ unit test
  @visibleForTesting
  static void resetForTesting() {
    _cache.clear();
    _assetLoaded = false;
  }
}
