/// Chi tiết một game trong thư viện Steam (tương ứng SteamGameItem trong steam-api-test)
class SteamGameItem {
  final int appId;
  final String name;
  double playtimeHours;
  final double? recentPlaytimeHours;
  final String? logoUrl;
  final String? iconUrl;
  final String storeUrl;
  num? initialPrice;
  num? finalPrice;
  num? lowestPrice;
  String? initialPriceFormatted;
  String? finalPriceFormatted;
  String? lowestPriceFormatted;
  int discountPercent;
  bool isFree;
  String status;
  DateTime? lastPlayed;
  DateTime? addedDate;
  DateTime? startDate;

  SteamGameItem({
    required this.appId,
    required this.name,
    required this.playtimeHours,
    this.recentPlaytimeHours,
    this.logoUrl,
    this.iconUrl,
    required this.storeUrl,
    this.initialPrice,
    this.finalPrice,
    this.lowestPrice,
    this.initialPriceFormatted,
    this.finalPriceFormatted,
    this.lowestPriceFormatted,
    this.discountPercent = 0,
    this.isFree = false,
    this.status = 'Affectionless',
    this.lastPlayed,
    this.addedDate,
    this.startDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
      'name': name,
      'playtimeHours': playtimeHours,
      'recentPlaytimeHours': recentPlaytimeHours,
      'logoUrl': logoUrl,
      'iconUrl': iconUrl,
      'storeUrl': storeUrl,
      'initialPrice': initialPrice,
      'finalPrice': finalPrice,
      'lowestPrice': lowestPrice,
      'initialPriceFormatted': initialPriceFormatted,
      'finalPriceFormatted': finalPriceFormatted,
      'lowestPriceFormatted': lowestPriceFormatted,
      'discountPercent': discountPercent,
      'isFree': isFree,
      'status': status,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'addedDate': addedDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
    };
  }
}

/// Nhật ký hoạt động chơi game (lưu số giờ chơi mới và thời điểm)
class GameActivity {
  final int? id;
  final String steamId;
  final int appId;
  final double playtimeHours;
  final DateTime loggedAt;
  final String? userName;
  final String? avatarUrl;

  GameActivity({
    this.id,
    required this.steamId,
    required this.appId,
    required this.playtimeHours,
    required this.loggedAt,
    this.userName,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'steam_id': steamId,
      'app_id': appId,
      'playtime_hours': playtimeHours,
      'logged_at': loggedAt.millisecondsSinceEpoch,
      'user_name': userName,
      'avatar_url': avatarUrl,
    };
  }

  factory GameActivity.fromMap(Map<String, dynamic> map) {
    return GameActivity(
      id: map['id'] as int?,
      steamId: (map['steam_id'] ?? '').toString(),
      appId: (map['app_id'] as num?)?.toInt() ?? 0,
      playtimeHours: (map['playtime_hours'] as num?)?.toDouble() ?? 0.0,
      loggedAt: DateTime.fromMillisecondsSinceEpoch(
        map['logged_at'] is int
            ? map['logged_at'] as int
            : (int.tryParse(map['logged_at'].toString()) ?? 0),
      ),
      userName: map['user_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

/// Thống kê thư viện Steam (tương ứng SteamLibraryStats trong steam-api-test)
class SteamLibraryStats {
  int totalGamesCount;
  double totalPlaytimeHours;
  double totalPlaytimeDays;
  num totalInitialPrice;
  num totalCurrentPrice;
  num totalLowestPrice;
  String totalInitialPriceFormatted;
  String totalCurrentPriceFormatted;
  String totalLowestPriceFormatted;
  String currency;
  String costPerHour;
  int gamesCountCalculated;
  String? note;

  SteamLibraryStats({
    this.totalGamesCount = 0,
    this.totalPlaytimeHours = 0.0,
    this.totalPlaytimeDays = 0.0,
    this.totalInitialPrice = 0,
    this.totalCurrentPrice = 0,
    this.totalLowestPrice = 0,
    this.totalInitialPriceFormatted = '0 ₫',
    this.totalCurrentPriceFormatted = '0 ₫',
    this.totalLowestPriceFormatted = '0 ₫',
    this.currency = 'VND',
    this.costPerHour = '0 ₫/h',
    this.gamesCountCalculated = 0,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalGamesCount': totalGamesCount,
      'totalPlaytimeHours': totalPlaytimeHours,
      'totalPlaytimeDays': totalPlaytimeDays,
      'totalInitialPrice': totalInitialPrice,
      'totalCurrentPrice': totalCurrentPrice,
      'totalLowestPrice': totalLowestPrice,
      'totalInitialPriceFormatted': totalInitialPriceFormatted,
      'totalCurrentPriceFormatted': totalCurrentPriceFormatted,
      'totalLowestPriceFormatted': totalLowestPriceFormatted,
      'currency': currency,
      'costPerHour': costPerHour,
      'gamesCountCalculated': gamesCountCalculated,
      'note': note,
    };
  }
}

/// Kết quả tổng hợp thông tin tài khoản Steam
class SteamCalculationResult {
  final String profileName;
  final String steamId;
  final int steamLevel;
  final int badgesCount;
  final String? realName;
  final String? avatarUrl;
  final String? avatarMedium;
  final String? avatarFull;
  final String? customUrl;
  final String? onlineState;
  final String? stateMessage;
  final String? privacyState;
  final int? visibilityState;
  final String? summary;
  final String totalValue; // Ô xanh: Tổng giá thấp nhất của toàn bộ game (All-time low / giá trị thực)
  final String todayPrice; // Today's prices: Tổng giá tất cả game thời điểm đó
  final String lowestPrice; // Giữ để tương thích ngược
  final dynamic gamesOwned;
  final String hoursPlayed;
  final String pricePerHour;
  final String vacStatus;
  final String? statusNote;
  final SteamLibraryStats? stats;
  final List<SteamGameItem> games;

  const SteamCalculationResult({
    required this.profileName,
    required this.steamId,
    required this.steamLevel,
    this.badgesCount = 0,
    this.realName,
    this.avatarUrl,
    this.avatarMedium,
    this.avatarFull,
    this.customUrl,
    this.onlineState,
    this.stateMessage,
    this.privacyState,
    this.visibilityState,
    this.summary,
    required this.totalValue,
    String? todayPrice,
    required this.lowestPrice,
    required this.gamesOwned,
    required this.hoursPlayed,
    required this.pricePerHour,
    required this.vacStatus,
    this.statusNote,
    this.stats,
    this.games = const [],
  }) : todayPrice = todayPrice ?? lowestPrice;

  Map<String, dynamic> toMap() {
    return {
      'profileName': profileName,
      'steamId': steamId,
      'steamLevel': steamLevel,
      'badgesCount': badgesCount,
      'realName': realName,
      'avatarUrl': avatarUrl,
      'avatarMedium': avatarMedium,
      'avatarFull': avatarFull,
      'customUrl': customUrl,
      'onlineState': onlineState,
      'stateMessage': stateMessage,
      'privacyState': privacyState,
      'visibilityState': visibilityState,
      'summary': summary,
      'totalValue': totalValue,
      'todayPrice': todayPrice,
      'lowestPrice': lowestPrice,
      'gamesOwned': gamesOwned,
      'hoursPlayed': hoursPlayed,
      'pricePerHour': pricePerHour,
      'vacStatus': vacStatus,
      'statusNote': statusNote,
      'stats': stats?.toMap(),
      'games': games.map((g) => g.toMap()).toList(),
    };
  }
}
