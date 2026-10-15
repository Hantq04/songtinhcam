/// Chi tiết một game trong thư viện Steam (tương ứng SteamGameItem trong steam-api-test)
class SteamGameItem {
  final int appId;
  final String name;
  final double playtimeHours;
  final double? recentPlaytimeHours;
  final String? logoUrl;
  final String? iconUrl;
  final String storeUrl;
  num? initialPrice;
  num? finalPrice;
  String? initialPriceFormatted;
  String? finalPriceFormatted;
  int discountPercent;
  bool isFree;

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
    this.initialPriceFormatted,
    this.finalPriceFormatted,
    this.discountPercent = 0,
    this.isFree = false,
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
      'initialPriceFormatted': initialPriceFormatted,
      'finalPriceFormatted': finalPriceFormatted,
      'discountPercent': discountPercent,
      'isFree': isFree,
    };
  }
}

/// Thống kê thư viện Steam (tương ứng SteamLibraryStats trong steam-api-test)
class SteamLibraryStats {
  int totalGamesCount;
  double totalPlaytimeHours;
  double totalPlaytimeDays;
  num totalInitialPrice;
  num totalCurrentPrice;
  String totalInitialPriceFormatted;
  String totalCurrentPriceFormatted;
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
    this.totalInitialPriceFormatted = '0 ₫',
    this.totalCurrentPriceFormatted = '0 ₫',
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
      'totalInitialPriceFormatted': totalInitialPriceFormatted,
      'totalCurrentPriceFormatted': totalCurrentPriceFormatted,
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
  final String totalValue;
  final String lowestPrice;
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
    required this.lowestPrice,
    required this.gamesOwned,
    required this.hoursPlayed,
    required this.pricePerHour,
    required this.vacStatus,
    this.statusNote,
    this.stats,
    this.games = const [],
  });

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
