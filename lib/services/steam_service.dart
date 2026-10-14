import 'dart:convert';
import 'dart:io';

class SteamCalculationResult {
  final String profileName;
  final String steamId;
  final int steamLevel;
  final String? avatarUrl;
  final String totalValue;
  final String lowestPrice;
  final dynamic gamesOwned;
  final String hoursPlayed;
  final String pricePerHour;
  final String vacStatus;
  final String? statusNote;

  const SteamCalculationResult({
    required this.profileName,
    required this.steamId,
    required this.steamLevel,
    this.avatarUrl,
    required this.totalValue,
    required this.lowestPrice,
    required this.gamesOwned,
    required this.hoursPlayed,
    required this.pricePerHour,
    required this.vacStatus,
    this.statusNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileName': profileName,
      'steamId': steamId,
      'steamLevel': steamLevel,
      'avatarUrl': avatarUrl,
      'totalValue': totalValue,
      'lowestPrice': lowestPrice,
      'gamesOwned': gamesOwned,
      'hoursPlayed': hoursPlayed,
      'pricePerHour': pricePerHour,
      'vacStatus': vacStatus,
      'statusNote': statusNote,
    };
  }
}

class SteamService {
  static final Map<String, String> _dnsCache = {};
  static final Map<String, num> _appPriceCache = {};

  /// Resolve hostname using Cloudflare & Google DNS-over-HTTPS (DoH)
  /// Crucial for networks/ISPs (such as in Vietnam) that block or poison Steam DNS.
  static Future<String?> _resolveHostWithDoH(String host) async {
    if (_dnsCache.containsKey(host)) return _dnsCache[host];

    final dohEndpoints = [
      'https://1.1.1.1/dns-query?name=$host&type=A',
      'https://8.8.8.8/resolve?name=$host&type=A',
    ];

    for (final endpoint in dohEndpoints) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final request = await client.getUrl(Uri.parse(endpoint));
        request.headers.set('accept', 'application/dns-json');
        final response = await request.close();
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final json = jsonDecode(body);
          final answers = json['Answer'] as List?;
          if (answers != null && answers.isNotEmpty) {
            final ip = answers.firstWhere(
              (a) => a['type'] == 1,
              orElse: () => null,
            )?['data'] as String?;
            if (ip != null && ip.isNotEmpty) {
              _dnsCache[host] = ip;
              client.close();
              return ip;
            }
          }
        }
        client.close();
      } catch (_) {}
    }
    return null;
  }

  /// Perform a resilient HTTP GET request with automatic DoH & SNI fallback.
  static Future<String> httpGet(String urlString) async {
    final uri = Uri.parse(urlString);

    // 1. Try standard HttpClient first
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
      final res = await req.close();
      if (res.statusCode == 301 || res.statusCode == 302) {
        final location = res.headers.value('location');
        client.close();
        if (location != null && location.isNotEmpty) {
          final redirectUri = uri.resolve(location);
          return await httpGet(redirectUri.toString());
        }
      }
      final body = await res.transform(utf8.decoder).join();
      client.close();
      return body;
    } catch (_) {
      // 2. Fallback to connecting via DoH IP + SecureSocket with correct SNI host
      final ip = await _resolveHostWithDoH(uri.host);
      if (ip == null) {
        throw Exception('Không thể phân giải tên miền: ${uri.host}');
      }

      final port = uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443);
      final rawSocket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));

      Socket socket = rawSocket;
      if (uri.scheme == 'https') {
        socket = await SecureSocket.secure(
          rawSocket,
          host: uri.host, // Preserves SNI for Steam servers
        );
      }

      final path = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      final request = 'GET $path HTTP/1.1\r\n'
          'Host: ${uri.host}\r\n'
          'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)\r\n'
          'Connection: close\r\n\r\n';

      socket.write(request);
      await socket.flush();

      final rawResponse = await utf8.decoder.bind(socket).join();
      await socket.close();

      // Check HTTP redirect in raw headers
      if (rawResponse.startsWith('HTTP/1.1 301') || rawResponse.startsWith('HTTP/1.1 302')) {
        final locMatch = RegExp(r'Location:\s*([^\r\n]+)', caseSensitive: false).firstMatch(rawResponse);
        if (locMatch != null) {
          final loc = locMatch.group(1)!.trim();
          final redirectUri = uri.resolve(loc);
          return await httpGet(redirectUri.toString());
        }
      }

      final splitIndex = rawResponse.indexOf('\r\n\r\n');
      if (splitIndex != -1) {
        return rawResponse.substring(splitIndex + 4);
      }
      return rawResponse;
    }
  }

  /// Parses various Steam ID formats into SteamID64
  static Future<String?> resolveSteamId(String input, {String? apiKey}) async {
    var trimmed = input.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    // Direct 17-digit SteamID64
    final profileMatch = RegExp(r'steamcommunity\.com\/profiles\/(\d{17})').firstMatch(trimmed);
    if (profileMatch != null) return profileMatch.group(1);
    if (RegExp(r'^\d{17}$').hasMatch(trimmed)) return trimmed;

    // SteamID3: [U:1:1208333168] or U:1:1208333168
    final id3Match = RegExp(r'\[?U:1:(\d+)\]?').firstMatch(trimmed);
    if (id3Match != null) {
      final accId = BigInt.parse(id3Match.group(1)!);
      final base = BigInt.parse('76561197960265728');
      return (base + accId).toString();
    }

    // SteamID2: STEAM_0:0:12345 or STEAM_1:1:12345
    final id2Match = RegExp(r'STEAM_[0-1]:([0-1]):(\d+)').firstMatch(trimmed);
    if (id2Match != null) {
      final y = BigInt.parse(id2Match.group(1)!);
      final z = BigInt.parse(id2Match.group(2)!);
      final base = BigInt.parse('76561197960265728');
      return (base + (z * BigInt.from(2)) + y).toString();
    }

    // Steam /user/ short URL
    final userMatch = RegExp(r'steamcommunity\.com\/user\/([^\/\?#]+)').firstMatch(trimmed);
    if (userMatch != null) {
      try {
        final profileUrl = 'https://steamcommunity.com/user/${userMatch.group(1)}';
        final redirectPage = await httpGet(profileUrl);
        final resolvedProfileMatch = RegExp(r'steamcommunity\.com\/profiles\/(\d{17})').firstMatch(redirectPage);
        if (resolvedProfileMatch != null) return resolvedProfileMatch.group(1);
      } catch (_) {}
    }

    // Vanity URL name
    String? vanitySlug;
    final idMatch = RegExp(r'steamcommunity\.com\/id\/([^\/\?#]+)').firstMatch(trimmed);
    if (idMatch != null) {
      vanitySlug = idMatch.group(1);
    } else if (!trimmed.startsWith('http')) {
      vanitySlug = trimmed;
    }

    if (vanitySlug != null) {
      // 1. Try ResolveVanityURL if API key is provided
      if (apiKey != null && apiKey.trim().isNotEmpty) {
        try {
          final resolveUrl = 'https://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=${apiKey.trim()}&vanityurl=$vanitySlug';
          final jsonStr = await httpGet(resolveUrl);
          final data = jsonDecode(jsonStr);
          if (data['response']?['success'] == 1 && data['response']?['steamid'] != null) {
            return data['response']['steamid'].toString();
          }
        } catch (_) {}
      }

      // 2. Fallback to public XML lookup
      try {
        final xml = await httpGet('https://steamcommunity.com/id/$vanitySlug/?xml=1');
        final xmlMatch = RegExp(r'<steamID64>(\d{17})<\/steamID64>').firstMatch(xml);
        if (xmlMatch != null) {
          return xmlMatch.group(1);
        }
      } catch (_) {}
    }

    return null;
  }

  /// Calculates real account stats using Steam Web API & Steam Store API
  static Future<SteamCalculationResult> calculateAccount({
    required String input,
    String? apiKey,
    required String currencyName,
  }) async {
    final cleanKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey.trim() : null;
    final steamId = await resolveSteamId(input, apiKey: cleanKey);

    if (steamId == null) {
      throw Exception('Không thể tìm thấy hoặc nhận dạng tài khoản Steam từ thông tin đã nhập.');
    }

    final currencyCode = currencyName == 'Vietnamese Dong' ? 'VND' : 'USD';
    final storeCountryCode = currencyCode == 'VND' ? 'vn' : 'us';

    String profileName = 'Steam User';
    String? avatarUrl;
    int steamLevel = 0;
    String vacStatus = 'In good standing';
    int gamesOwned = 0;
    int totalPlaytimeMinutes = 0;
    List<Map<String, dynamic>> gamesList = [];
    String? statusNote;

    // 1. Fetch user profile summary & level
    if (cleanKey != null) {
      // Using Steam Web API
      try {
        final summaryUrl = 'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$cleanKey&steamids=$steamId';
        final summaryStr = await httpGet(summaryUrl);
        final summaryData = jsonDecode(summaryStr);
        final players = summaryData['response']?['players'] as List?;
        if (players != null && players.isNotEmpty) {
          final player = players.first;
          profileName = player['personaname'] ?? profileName;
          avatarUrl = player['avatarfull'] ?? player['avatarmedium'] ?? player['avatar'];
          final visibility = player['communityvisibilitystate'] ?? 0;
          if (visibility != 3) {
            statusNote = 'Hồ sơ Steam đang ở chế độ Riêng tư (Private). Một số thông tin có thể không hiển thị đầy đủ.';
          }
        }
      } catch (_) {}

      // Fetch Steam level
      try {
        final levelUrl = 'https://api.steampowered.com/IPlayerService/GetSteamLevel/v1/?key=$cleanKey&steamid=$steamId';
        final levelStr = await httpGet(levelUrl);
        final levelData = jsonDecode(levelStr);
        steamLevel = levelData['response']?['player_level'] ?? 0;
      } catch (_) {}

      // Fetch VAC Bans
      try {
        final bansUrl = 'https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=$cleanKey&steamids=$steamId';
        final bansStr = await httpGet(bansUrl);
        final bansData = jsonDecode(bansStr);
        final players = bansData['players'] as List?;
        if (players != null && players.isNotEmpty) {
          final ban = players.first;
          final isVacBanned = ban['VACBanned'] == true;
          final numBans = ban['NumberOfVACBans'] ?? 0;
          vacStatus = isVacBanned ? 'Banned ($numBans VAC ban)' : 'In good standing';
        }
      } catch (_) {}

      // Fetch Owned Games
      try {
        final gamesUrl = 'https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=$cleanKey&steamid=$steamId&include_appinfo=1&include_played_free_games=1';
        final gamesStr = await httpGet(gamesUrl);
        final gamesData = jsonDecode(gamesStr);
        final response = gamesData['response'];
        if (response != null) {
          gamesOwned = response['game_count'] ?? 0;
          final games = response['games'] as List?;
          if (games != null) {
            for (final g in games) {
              final playtime = g['playtime_forever'] as int? ?? 0;
              totalPlaytimeMinutes += playtime;
              gamesList.add({
                'appid': g['appid'],
                'name': g['name'] ?? '',
                'playtime': playtime,
              });
            }
          }
        }
      } catch (_) {}
    } else {
      // Fallback: Fetch Public XML profile if no API key provided
      try {
        final xml = await httpGet('https://steamcommunity.com/profiles/$steamId/?xml=1');
        final nameMatch = RegExp(r'<steamID><!\[CDATA\[(.*?)\]\]><\/steamID>').firstMatch(xml);
        if (nameMatch != null) profileName = nameMatch.group(1)!;

        final avatarMatch = RegExp(r'<avatarFull><!\[CDATA\[(.*?)\]\]><\/avatarFull>').firstMatch(xml);
        if (avatarMatch != null) avatarUrl = avatarMatch.group(1);

        final vacMatch = RegExp(r'<vacBanned>(\d+)<\/vacBanned>').firstMatch(xml);
        if (vacMatch != null && vacMatch.group(1) == '1') {
          vacStatus = 'Banned (1 VAC ban)';
        }

        statusNote = 'Bạn chưa nhập Steam Web API Key. Vui lòng nhập API Key để lấy danh sách game và tính giá trị tài khoản chính xác!';
      } catch (_) {}
    }

    // 2. Calculate account value and game pricing
    double totalValueNum = 0.0;
    double lowestPriceNum = 0.0;

    if (gamesList.isNotEmpty) {
      // Sort games by playtime descending
      gamesList.sort((a, b) => (b['playtime'] as int).compareTo(a['playtime'] as int));

      // Batch query prices for top played games (up to 20 games to avoid strict rate limits)
      final sampleCount = gamesList.length < 20 ? gamesList.length : 20;
      final gamesToPrice = gamesList.take(sampleCount).toList();

      int pricedGamesCount = 0;
      double pricedGamesTotal = 0;
      double pricedGamesDiscountTotal = 0;

      for (final game in gamesToPrice) {
        final appId = game['appid'].toString();
        final cacheKey = '$appId-$currencyCode';

        num? initialPrice;
        num? finalPrice;

        if (_appPriceCache.containsKey(cacheKey)) {
          initialPrice = _appPriceCache[cacheKey];
          finalPrice = initialPrice;
        } else {
          try {
            final storeUrl = 'https://store.steampowered.com/api/appdetails?appids=$appId&cc=$storeCountryCode&filters=price_overview';
            final storeStr = await httpGet(storeUrl);
            final storeJson = jsonDecode(storeStr);
            final appData = storeJson[appId];
            if (appData != null && appData['success'] == true) {
              final overview = appData['data']?['price_overview'];
              if (overview != null) {
                // Steam store returns minor currency units (e.g., cents or minor VND units)
                initialPrice = (overview['initial'] as num?) ?? (overview['final'] as num?);
                finalPrice = overview['final'] as num?;
                if (currencyCode == 'USD' && initialPrice != null) {
                  initialPrice = initialPrice / 100.0;
                  finalPrice = (finalPrice ?? 0) / 100.0;
                } else if (currencyCode == 'VND' && initialPrice != null) {
                  // In VND, Steam returns minor units x100 (e.g. 14000000 = 140.000₫)
                  initialPrice = initialPrice / 100.0;
                  finalPrice = (finalPrice ?? 0) / 100.0;
                }
                if (initialPrice != null && initialPrice > 0) {
                  _appPriceCache[cacheKey] = initialPrice;
                }
              }
            }
          } catch (_) {}
        }

        if (initialPrice != null && initialPrice > 0) {
          pricedGamesCount++;
          pricedGamesTotal += initialPrice;
          pricedGamesDiscountTotal += (finalPrice ?? (initialPrice * 0.35));
        }
      }

      if (pricedGamesCount > 0) {
        final avgInitial = pricedGamesTotal / pricedGamesCount;
        final avgDiscount = pricedGamesDiscountTotal / pricedGamesCount;

        // Extrapolate for remaining games
        final remainingGames = gamesList.length - pricedGamesCount;
        totalValueNum = pricedGamesTotal + (remainingGames * avgInitial * 0.7); // 70% weight for back-catalog
        lowestPriceNum = pricedGamesDiscountTotal + (remainingGames * avgDiscount * 0.7);
      } else {
        // Fallback realistic baseline if all sampled games were free-to-play
        final estimatedPaid = (gamesOwned * 0.5).round();
        if (currencyCode == 'VND') {
          totalValueNum = (estimatedPaid * 250000.0);
          lowestPriceNum = totalValueNum * 0.35;
        } else {
          totalValueNum = (estimatedPaid * 15.0);
          lowestPriceNum = totalValueNum * 0.35;
        }
      }
    }

    final totalHours = (totalPlaytimeMinutes / 60.0);
    double pricePerHourNum = 0.0;
    if (totalHours > 0 && totalValueNum > 0) {
      pricePerHourNum = totalValueNum / totalHours;
    }

    final formattedTotalValue = gamesOwned > 0 || cleanKey != null
        ? _formatCurrency(totalValueNum, currencyCode)
        : 'Cần API Key';

    final formattedLowestPrice = gamesOwned > 0 || cleanKey != null
        ? _formatCurrency(lowestPriceNum, currencyCode)
        : 'Cần API Key';

    final formattedPricePerHour = gamesOwned > 0 || cleanKey != null
        ? _formatPricePerHour(pricePerHourNum, currencyCode)
        : '—';

    final formattedHours = gamesOwned > 0 || cleanKey != null
        ? _formatHours(totalPlaytimeMinutes)
        : 'Cần API Key';

    final displayGamesCount = gamesOwned > 0 || cleanKey != null ? gamesOwned : 'Cần API Key';

    return SteamCalculationResult(
      profileName: profileName,
      steamId: steamId,
      steamLevel: steamLevel,
      avatarUrl: avatarUrl,
      totalValue: formattedTotalValue,
      lowestPrice: formattedLowestPrice,
      gamesOwned: displayGamesCount,
      hoursPlayed: formattedHours,
      pricePerHour: formattedPricePerHour,
      vacStatus: vacStatus,
      statusNote: statusNote,
    );
  }

  static String _formatCurrency(num amount, String currencyCode) {
    if (currencyCode == 'VND') {
      final intVal = amount.round();
      final str = intVal.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        buffer.write(str[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write('.');
        }
      }
      return '${buffer.toString().split('').reversed.join('')} ₫';
    } else {
      final parts = amount.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        buffer.write(intPart[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write(',');
        }
      }
      return '\$${buffer.toString().split('').reversed.join('')}.$decPart';
    }
  }

  static String _formatPricePerHour(num amount, String currencyCode) {
    if (currencyCode == 'VND') {
      final intVal = amount.round();
      final str = intVal.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        buffer.write(str[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write('.');
        }
      }
      return '${buffer.toString().split('').reversed.join('')} ₫/h';
    } else {
      return '\$${amount.toStringAsFixed(2)}/h';
    }
  }

  static String _formatHours(int totalMinutes) {
    final hours = (totalMinutes / 60).round();
    final str = hours.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return '${buffer.toString().split('').reversed.join('')}h';
  }
}
