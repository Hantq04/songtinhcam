import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../models/steam_models.dart';
import '../utils/steam_formatters.dart';

export '../models/steam_models.dart';
export '../widgets/steam_image.dart';

class SteamService {
  static String? _cachedEnvApiKey;

  /// Steam Web API Key: Đọc từ biến môi trường STEAM_API_KEY (--dart-define),
  /// từ file .env trên máy host, hoặc từ asset .env của Flutter app.
  static Future<String> getApiKey() async {
    if (_cachedEnvApiKey != null && _cachedEnvApiKey!.isNotEmpty) {
      return _cachedEnvApiKey!;
    }

    const envVal = String.fromEnvironment('STEAM_API_KEY');
    if (envVal.isNotEmpty) {
      _cachedEnvApiKey = envVal;
      return envVal;
    }

    // 1. Đọc từ file hệ thống (khi chạy Desktop, CLI, unit test)
    try {
      final candidatePaths = [
        '.env',
        '../.env',
        '../../.env',
        '../../../.env',
        '../../../../.env',
      ];
      for (final path in candidatePaths) {
        final envFile = File(path);
        if (envFile.existsSync()) {
          for (final line in envFile.readAsLinesSync()) {
            final trimmed = line.trim();
            if (trimmed.startsWith('#') || trimmed.isEmpty) continue;
            if (trimmed.startsWith('STEAM_API_KEY=')) {
              final key = trimmed.substring('STEAM_API_KEY='.length).trim();
              if (key.isNotEmpty) {
                _cachedEnvApiKey = key;
                return key;
              }
            }
          }
        }
      }
    } catch (_) {}

    // 2. Đọc từ asset bundle của Flutter (khi chạy trên Android/iOS thiết bị thật hoặc máy ảo)
    try {
      final content = await rootBundle.loadString('.env');
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#') || trimmed.isEmpty) continue;
        if (trimmed.startsWith('STEAM_API_KEY=')) {
          final key = trimmed.substring('STEAM_API_KEY='.length).trim();
          if (key.isNotEmpty) {
            _cachedEnvApiKey = key;
            return key;
          }
        }
      }
    } catch (_) {}

    return '';
  }

  /// Getter đồng bộ kiểm tra cache hoặc biến môi trường/file .env
  static String get defaultApiKey {
    if (_cachedEnvApiKey != null && _cachedEnvApiKey!.isNotEmpty) {
      return _cachedEnvApiKey!;
    }

    const envVal = String.fromEnvironment('STEAM_API_KEY');
    if (envVal.isNotEmpty) {
      _cachedEnvApiKey = envVal;
      return envVal;
    }

    try {
      final candidatePaths = [
        '.env',
        '../.env',
        '../../.env',
        '../../../.env',
        '../../../../.env',
      ];
      for (final path in candidatePaths) {
        final envFile = File(path);
        if (envFile.existsSync()) {
          for (final line in envFile.readAsLinesSync()) {
            final trimmed = line.trim();
            if (trimmed.startsWith('#') || trimmed.isEmpty) continue;
            if (trimmed.startsWith('STEAM_API_KEY=')) {
              final key = trimmed.substring('STEAM_API_KEY='.length).trim();
              if (key.isNotEmpty) {
                _cachedEnvApiKey = key;
                return key;
              }
            }
          }
        }
      }
    } catch (_) {}

    return _cachedEnvApiKey ?? '';
  }

  static final Map<String, List<String>> _dnsCache = {};
  static final Map<String, num> _appPriceCache = {};
  static final Map<int, double> _lowestDiscountRatioCache = {};

  /// Phân giải IP bằng Google DoH & Cloudflare DoH (hỗ trợ vượt chặn DNS tại VN)
  static Future<List<String>> _resolveHostAllIps(String host) async {
    if (_dnsCache.containsKey(host) && _dnsCache[host]!.isNotEmpty) {
      return _dnsCache[host]!;
    }

    final dohEndpoints = [
      'https://8.8.8.8/resolve?name=$host&type=A',
      'https://1.1.1.1/dns-query?name=$host&type=A',
    ];

    for (final endpoint in dohEndpoints) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        client.badCertificateCallback = (cert, host, port) => true;
        final request = await client.getUrl(Uri.parse(endpoint));
        request.headers.set('accept', 'application/dns-json');
        final response = await request.close();
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final json = jsonDecode(body);
          final answers = json['Answer'] as List?;
          if (answers != null && answers.isNotEmpty) {
            final ips = answers
                .where((a) => a['type'] == 1 && a['data'] != null)
                .map((a) => a['data'] as String)
                .toList();
            client.close();
            if (ips.isNotEmpty) {
              _dnsCache[host] = ips;
              return ips;
            }
          }
        }
        client.close();
      } catch (_) {}
    }
    return [];
  }

  /// Request HTTP GET linh hoạt với fallback DoH + SNI cho Steam tại Việt Nam
  static Future<String> httpGet(String urlString) async {
    final uri = Uri.parse(urlString);

    // 1. Thử HttpClient chuẩn trước
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      client.badCertificateCallback = (cert, host, port) => true;
      final req = await client.getUrl(uri);
      req.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );
      req.headers.set('Accept-Language', 'en-US,en;q=0.9');
      final res = await req.close();
      if (res.statusCode == 301 || res.statusCode == 302) {
        final location = res.headers.value('location');
        client.close();
        if (location != null && location.isNotEmpty) {
          return await httpGet(uri.resolve(location).toString());
        }
      }
      final body = await res.transform(utf8.decoder).join();
      client.close();
      if (body.isNotEmpty &&
          !body.contains('Access Blocked') &&
          !body.contains('FortiGuard')) {
        return body;
      }
    } catch (_) {}

    // 2. Fallback sử dụng IP phân giải qua DoH kết nối Socket bảo lưu SNI
    final ips = await _resolveHostAllIps(uri.host);
    if (ips.isEmpty) {
      throw Exception('Could not resolve hostname: ${uri.host}');
    }

    for (final ip in ips) {
      try {
        final port = uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443);
        final rawSocket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(seconds: 4),
        );
        Socket socket = rawSocket;
        if (uri.scheme == 'https') {
          socket = await SecureSocket.secure(
            rawSocket,
            host: uri.host,
            onBadCertificate: (cert) => true,
          );
        }

        final path = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
        final request = 'GET $path HTTP/1.1\r\n'
            'Host: ${uri.host}\r\n'
            'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36\r\n'
            'Accept-Language: en-US,en;q=0.9\r\n'
            'Connection: close\r\n\r\n';

        socket.write(request);
        await socket.flush();

        final rawResponse = await utf8.decoder.bind(socket).join();
        await socket.close();

        if (rawResponse.startsWith('HTTP/1.1 301') ||
            rawResponse.startsWith('HTTP/1.1 302')) {
          final locMatch = RegExp(
            r'Location:\s*([^\r\n]+)',
            caseSensitive: false,
          ).firstMatch(rawResponse);
          if (locMatch != null) {
            final loc = locMatch.group(1)!.trim();
            return await httpGet(uri.resolve(loc).toString());
          }
        }

        final splitIndex = rawResponse.indexOf('\r\n\r\n');
        final body = splitIndex != -1
            ? rawResponse.substring(splitIndex + 4)
            : rawResponse;
        if (body.isNotEmpty &&
            !body.contains('Access Blocked') &&
            !body.contains('FortiGuard')) {
          return body;
        }
      } catch (_) {}
    }

    throw Exception('Could not connect to Steam (${uri.host}).');
  }

  /// Xây dựng URL XML tương tự buildSteamXmlUrl trong steam-api-test
  static String buildSteamXmlUrl(String input) {
    var trimmed = input.trim().replaceAll(RegExp(r'/+$'), '');

    final profileMatch = RegExp(
      r'https?://steamcommunity\.com/profiles/(\d+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (profileMatch != null) {
      return 'https://steamcommunity.com/profiles/${profileMatch.group(1)}/?xml=1';
    }

    final vanityMatch = RegExp(
      r'https?://steamcommunity\.com/id/([a-zA-Z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (vanityMatch != null) {
      return 'https://steamcommunity.com/id/${vanityMatch.group(1)}/?xml=1';
    }

    if (RegExp(r'^\d{17}$').hasMatch(trimmed)) {
      return 'https://steamcommunity.com/profiles/$trimmed/?xml=1';
    }

    // Xử lý SteamID3 hoặc SteamID2 nếu có
    final id3Match = RegExp(r'\[?U:1:(\d+)\]?').firstMatch(trimmed);
    if (id3Match != null) {
      final accId = BigInt.parse(id3Match.group(1)!);
      final base = BigInt.parse('76561197960265728');
      final steamId64 = (base + accId).toString();
      return 'https://steamcommunity.com/profiles/$steamId64/?xml=1';
    }

    final id2Match = RegExp(r'STEAM_[0-1]:([0-1]):(\d+)').firstMatch(trimmed);
    if (id2Match != null) {
      final y = BigInt.parse(id2Match.group(1)!);
      final z = BigInt.parse(id2Match.group(2)!);
      final base = BigInt.parse('76561197960265728');
      final steamId64 = (base + (z * BigInt.from(2)) + y).toString();
      return 'https://steamcommunity.com/profiles/$steamId64/?xml=1';
    }

    return 'https://steamcommunity.com/id/$trimmed/?xml=1';
  }

  /// Trích xuất nội dung thẻ XML (hỗ trợ cả CDATA và text thông thường)
  static String? _extractTagValue(String xml, String tag) {
    final match = RegExp(
      '<$tag>(?:<!\\[CDATA\\[(.*?)\\]\\]>|(.*?))<\\/$tag>',
      dotAll: true,
    ).firstMatch(xml);
    if (match != null) {
      return (match.group(1) ?? match.group(2))?.trim();
    }
    return null;
  }

  /// Lấy dữ liệu hồ sơ và tính toán giá trị tài khoản (Port toàn bộ từ SteamApiService.java)
  static Future<SteamCalculationResult> calculateAccount({
    required String input,
    required String currencyName,
  }) async {
    if (input.trim().isEmpty) {
      throw Exception('Please provide a Steam URL or SteamID');
    }

    final targetXmlUrl = buildSteamXmlUrl(input);
    final xmlBody = await httpGet(targetXmlUrl);

    // Kiểm tra lỗi từ XML
    if (xmlBody.contains('<error>') || xmlBody.startsWith('<response>')) {
      final errorMsg = _extractTagValue(xmlBody, 'error');
      throw Exception(errorMsg ?? 'Could not find a valid Steam profile');
    }

    // 1. Phân tích XML Profile
    final steamId64 = _extractTagValue(xmlBody, 'steamID64') ?? '';
    final personaName = _extractTagValue(xmlBody, 'steamID') ?? 'Steam User';
    final realName = _extractTagValue(xmlBody, 'realname');
    final customUrl = _extractTagValue(xmlBody, 'customURL');
    final onlineState = _extractTagValue(xmlBody, 'onlineState');
    final stateMessage = _extractTagValue(xmlBody, 'stateMessage');
    final privacyState = _extractTagValue(xmlBody, 'privacyState');
    final visibilityStateStr = _extractTagValue(xmlBody, 'visibilityState');
    final avatar = _extractTagValue(xmlBody, 'avatarIcon');
    final avatarMedium = _extractTagValue(xmlBody, 'avatarMedium');
    final avatarFull = _extractTagValue(xmlBody, 'avatarFull');
    final summary = _extractTagValue(xmlBody, 'summary');
    final vacBanned = _extractTagValue(xmlBody, 'vacBanned') == '1';

    int? visibilityState;
    if (visibilityStateStr != null && visibilityStateStr.isNotEmpty) {
      visibilityState = int.tryParse(visibilityStateStr);
    }

    // Parse danh sách mostPlayedGames từ XML (kể cả khi không có API key)
    final List<SteamGameItem> xmlGames = [];
    final mostPlayedMatches = RegExp(
      r'<mostPlayedGame>([\s\S]*?)<\/mostPlayedGame>',
    ).allMatches(xmlBody);

    for (final m in mostPlayedMatches) {
      final gameXml = m.group(1)!;
      final gameName = _extractTagValue(gameXml, 'gameName') ?? 'Steam Game';
      final gameLink = _extractTagValue(gameXml, 'gameLink') ?? '';
      final gameIcon = _extractTagValue(gameXml, 'gameIcon');
      final gameLogo = _extractTagValue(gameXml, 'gameLogo');
      final hoursPlayedStr = _extractTagValue(gameXml, 'hoursPlayed');
      final hoursOnRecordStr = _extractTagValue(gameXml, 'hoursOnRecord');

      final appIdMatch = RegExp(r'/app/(\d+)').firstMatch(gameLink);
      if (appIdMatch == null) continue;
      final appId = int.parse(appIdMatch.group(1)!);

      final playtimeHours = double.tryParse(
            (hoursOnRecordStr ?? '0').replaceAll(',', '').trim(),
          ) ??
          0.0;
      final recentHours = double.tryParse(
        (hoursPlayedStr ?? '0').replaceAll(',', '').trim(),
      );

      xmlGames.add(SteamGameItem(
        appId: appId,
        name: gameName,
        playtimeHours: playtimeHours,
        recentPlaytimeHours: recentHours,
        iconUrl: gameIcon,
        logoUrl: gameLogo,
        storeUrl: gameLink.isNotEmpty
            ? gameLink
            : 'https://store.steampowered.com/app/$appId',
      ));
    }

    // 2. Scrape Profile HTML để lấy Level, Badges count và Total games count
    int steamLevel = 0;
    int badgesCount = 0;
    int? htmlTotalGames;

    if (steamId64.isNotEmpty) {
      try {
        final profileHtmlUrl = 'https://steamcommunity.com/profiles/$steamId64';
        final html = await httpGet(profileHtmlUrl);

        // Level
        final lvlMatch = RegExp(r'class="friendPlayerLevelNum">(\d+)</span>')
            .firstMatch(html);
        if (lvlMatch != null) {
          steamLevel = int.tryParse(lvlMatch.group(1)!) ?? 0;
        }

        // Tổng số game: <a href=".../games/?tab=all">...<span class="profile_count_link_total">173</span>
        final gamesMatch = RegExp(
          r'href="[^"]*?/games/[^"]*"[\s\S]*?class="profile_count_link_total">\s*([\d,]+)',
          caseSensitive: false,
        ).firstMatch(html);
        if (gamesMatch != null) {
          htmlTotalGames = int.tryParse(
            gamesMatch.group(1)!.replaceAll(',', '').trim(),
          );
        }

        // Số lượng Badges: <a href=".../badges/?">...<span class="profile_count_link_total">21</span>
        final badgesMatch = RegExp(
          r'href="[^"]*?/badges/?"[\s\S]*?class="profile_count_link_total">\s*([\d,]+)',
          caseSensitive: false,
        ).firstMatch(html);
        if (badgesMatch != null) {
          badgesCount = int.tryParse(
                badgesMatch.group(1)!.replaceAll(',', '').trim(),
              ) ??
              0;
        }
      } catch (_) {}
    }

    // 3. Lấy toàn bộ game qua Steam Web API GetOwnedGames (sử dụng API key từ biến môi trường hoặc .env)
    final cleanApiKey = await getApiKey();

    List<SteamGameItem> games = [];
    bool fetchedFromWebApi = false;

    if (cleanApiKey.isNotEmpty && steamId64.isNotEmpty) {
      try {
        final apiUrl =
            'https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=$cleanApiKey&steamid=$steamId64&include_appinfo=1&include_played_free_games=1';
        final jsonStr = await httpGet(apiUrl);
        final data = jsonDecode(jsonStr);
        final rawGames = data['response']?['games'] as List?;

        if (rawGames != null && rawGames.isNotEmpty) {
          for (final g in rawGames) {
            final appId = g['appid'] as int;
            final name = (g['name'] as String?)?.trim();
            if (name == null || name.isEmpty) continue;
            final playtimeMinutes = g['playtime_forever'] as int? ?? 0;
            final playtimeHours =
                ((playtimeMinutes / 60.0) * 10).round() / 10.0;
            final iconHash = (g['img_icon_url'] as String?) ?? '';
            final iconUrl = iconHash.isNotEmpty
                ? 'https://media.steampowered.com/steamcommunity/public/images/apps/$appId/$iconHash.jpg'
                : null;
            final logoUrl =
                'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/$appId/capsule_184x69.jpg';

            games.add(SteamGameItem(
              appId: appId,
              name: name,
              playtimeHours: playtimeHours,
              iconUrl: iconUrl,
              logoUrl: logoUrl,
              storeUrl: 'https://store.steampowered.com/app/$appId',
            ));
          }
          fetchedFromWebApi = true;
        }
      } catch (_) {}
    }

    // Fallback nếu không có Web API hoặc Web API trả về rỗng
    if (!fetchedFromWebApi || games.isEmpty) {
      games = xmlGames;
    }

    // Sắp xếp game theo số giờ chơi giảm dần
    games.sort((a, b) => b.playtimeHours.compareTo(a.playtimeHours));

    // 4. Lấy giá từ Steam Store API theo batch 30 appid (như steam-api-test)
    final currencyCode = currencyName == 'Vietnamese Dong' ? 'VND' : 'USD';
    final storeCountryCode = currencyCode == 'VND' ? 'vn' : 'us';

    await _fetchStorePrices(games, storeCountryCode, currencyCode);
    await _fetchHistoricalLows(games, currencyCode);

    // 5. Tính toán thống kê thư viện
    final stats = _calculateLibraryStats(
      games: games,
      totalGamesCount: htmlTotalGames,
      currencyCode: currencyCode,
      hasApiKey: fetchedFromWebApi,
    );

    String? statusNote;
    if (visibilityState != null && visibilityState != 3) {
      statusNote =
          'Steam profile is set to Private. Some information may not be fully displayed.';
    } else if (!fetchedFromWebApi) {
      statusNote = stats.note;
    }

    final vacStatus = vacBanned ? 'Banned (1 VAC ban)' : 'In good standing';

    return SteamCalculationResult(
      profileName: personaName,
      steamId: steamId64,
      steamLevel: steamLevel,
      badgesCount: badgesCount,
      realName: realName,
      avatarUrl: avatarFull ?? avatarMedium ?? avatar,
      avatarMedium: avatarMedium,
      avatarFull: avatarFull,
      customUrl: customUrl,
      onlineState: onlineState,
      stateMessage: stateMessage,
      privacyState: privacyState,
      visibilityState: visibilityState,
      summary: summary,
      totalValue: stats.totalLowestPriceFormatted,
      todayPrice: stats.totalCurrentPriceFormatted,
      lowestPrice: stats.totalCurrentPriceFormatted,
      gamesOwned: stats.totalGamesCount,
      hoursPlayed: '${stats.totalPlaytimeHours.toStringAsFixed(1)}h',
      pricePerHour: stats.costPerHour,
      vacStatus: vacStatus,
      statusNote: statusNote,
      stats: stats,
      games: games,
    );
  }

  /// Truy vấn giá hàng loạt theo batch 30 game (đặc trưng từ steam-api-test)
  static Future<void> _fetchStorePrices(
    List<SteamGameItem> games,
    String storeCountryCode,
    String currencyCode,
  ) async {
    if (games.isEmpty) return;

    // Lấy tối đa 60 game nhiều giờ chơi nhất để batch query tránh bị Store API rate-limit
    final gamesToPrice = games.take(60).toList();
    const batchSize = 30;

    for (int i = 0; i < gamesToPrice.length; i += batchSize) {
      final end = (i + batchSize < gamesToPrice.length)
          ? i + batchSize
          : gamesToPrice.length;
      final batch = gamesToPrice.sublist(i, end);
      final appIds = batch.map((g) => g.appId).join(',');

      if (appIds.isEmpty) continue;

      try {
        final storeUrl =
            'https://store.steampowered.com/api/appdetails?appids=$appIds&cc=$storeCountryCode&filters=price_overview';
        final storeStr = await httpGet(storeUrl);
        final storeData = jsonDecode(storeStr);

        for (final game in batch) {
          final appIdStr = game.appId.toString();
          final cacheKey = '$appIdStr-$currencyCode';

          if (_appPriceCache.containsKey(cacheKey)) {
            final cachedInitial = _appPriceCache[cacheKey]!;
            game.initialPrice = cachedInitial;
            game.finalPrice = cachedInitial;
            game.initialPriceFormatted = _formatAmount(cachedInitial, currencyCode);
            game.finalPriceFormatted = _formatAmount(cachedInitial, currencyCode);
            game.isFree = cachedInitial == 0;
            continue;
          }

          if (storeData is Map && storeData.containsKey(appIdStr)) {
            final appObj = storeData[appIdStr];
            if (appObj is Map && appObj['success'] == true) {
              final dataObj = appObj['data'];
              if (dataObj is Map) {
                final priceOverview = dataObj['price_overview'];
                if (priceOverview is Map) {
                  // Steam trả về đơn vị tiền tệ nhân 100
                  final rawInitial = priceOverview['initial'] as num? ??
                      priceOverview['final'] as num? ??
                      0;
                  final rawFinal = priceOverview['final'] as num? ?? 0;
                  final discount =
                      priceOverview['discount_percent'] as int? ?? 0;

                  final initial = currencyCode == 'USD'
                      ? rawInitial / 100.0
                      : (rawInitial / 100).round();
                  final finalPrice = currencyCode == 'USD'
                      ? rawFinal / 100.0
                      : (rawFinal / 100).round();

                  game.initialPrice = initial;
                  game.finalPrice = finalPrice;
                  game.discountPercent = discount;
                  game.initialPriceFormatted = _formatAmount(initial, currencyCode);
                  game.finalPriceFormatted = _formatAmount(finalPrice, currencyCode);
                  game.isFree = false;

                  if (initial > 0) {
                    _appPriceCache[cacheKey] = initial;
                  }
                  continue;
                }
              }
            }
          }

          // Game miễn phí hoặc không còn kinh doanh
          game.initialPrice = 0;
          game.finalPrice = 0;
          game.discountPercent = 0;
          game.initialPriceFormatted = currencyCode == 'VND' ? 'Miễn phí' : 'Free';
          game.finalPriceFormatted = currencyCode == 'VND' ? 'Miễn phí' : 'Free';
          game.isFree = true;
        }
      } catch (_) {
        // Tiếp tục xử lý batch tiếp theo nếu một batch gặp lỗi
      }
    }
  }

  /// Lấy mức giá thấp nhất lịch sử (All-Time Low) từ CheapShark API
  static Future<void> _fetchHistoricalLows(
    List<SteamGameItem> games,
    String currencyCode,
  ) async {
    final paidGames =
        games.where((g) => !g.isFree && (g.initialPrice ?? 0) > 0).toList();
    if (paidGames.isEmpty) {
      for (final g in games) {
        g.lowestPrice = g.finalPrice ?? g.initialPrice ?? 0;
        g.lowestPriceFormatted = _formatAmount(g.lowestPrice!, currencyCode);
      }
      return;
    }

    final gamesToQuery = paidGames.take(60).toList();
    final List<int> uncachedAppIds = [];
    for (final g in gamesToQuery) {
      if (!_lowestDiscountRatioCache.containsKey(g.appId)) {
        uncachedAppIds.add(g.appId);
      }
    }

    if (uncachedAppIds.isNotEmpty) {
      const batchSize = 30;
      for (int i = 0; i < uncachedAppIds.length; i += batchSize) {
        final end = (i + batchSize < uncachedAppIds.length)
            ? i + batchSize
            : uncachedAppIds.length;
        final batch = uncachedAppIds.sublist(i, end);
        final appIdsStr = batch.join(',');

        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 4);
          final uri = Uri.parse(
              'https://www.cheapshark.com/api/1.0/deals?steamAppID=$appIdsStr&sortBy=Price');
          final req = await client.getUrl(uri);
          req.headers
              .set('User-Agent', 'SongTinhCam/1.0 (admin@songtinhcam.vn)');
          final res = await req.close();
          final body = await res.transform(utf8.decoder).join();
          client.close();

          if (res.statusCode == 200) {
            final deals = jsonDecode(body);
            if (deals is List) {
              final Map<int, String> appToGameId = {};
              for (final d in deals) {
                if (d is Map) {
                  final sAppId =
                      int.tryParse(d['steamAppID']?.toString() ?? '');
                  final gId = d['gameID']?.toString();
                  if (sAppId != null &&
                      gId != null &&
                      !appToGameId.containsKey(sAppId)) {
                    appToGameId[sAppId] = gId;
                  }
                }
              }

              final detailFutures = appToGameId.entries.map((entry) async {
                final aId = entry.key;
                final gId = entry.value;
                try {
                  final gClient = HttpClient();
                  gClient.connectionTimeout = const Duration(seconds: 3);
                  final gUri = Uri.parse(
                      'https://www.cheapshark.com/api/1.0/games?id=$gId');
                  final gReq = await gClient.getUrl(gUri);
                  gReq.headers.set(
                      'User-Agent', 'SongTinhCam/1.0 (admin@songtinhcam.vn)');
                  final gRes = await gReq.close();
                  final gBody = await gRes.transform(utf8.decoder).join();
                  gClient.close();

                  if (gRes.statusCode == 200) {
                    final gData = jsonDecode(gBody);
                    final lowestStr = gData['cheapestPriceEver']?['price'];
                    final retailStr =
                        (gData['deals'] as List?)?.firstOrNull?['retailPrice'];
                    final lowest = double.tryParse(lowestStr?.toString() ?? '');
                    final retail = double.tryParse(retailStr?.toString() ?? '');
                    if (lowest != null && retail != null && retail > 0) {
                      final ratio = (lowest / retail).clamp(0.0, 1.0);
                      _lowestDiscountRatioCache[aId] = ratio;
                    }
                  }
                } catch (_) {}
              });

              await Future.wait(detailFutures);
            }
          }
        } catch (_) {}
      }
    }

    // Áp dụng lowestPrice cho từng game
    for (final game in games) {
      if (game.isFree) {
        game.lowestPrice = 0;
        game.lowestPriceFormatted = currencyCode == 'VND' ? 'Miễn phí' : 'Free';
        continue;
      }

      final ratio = _lowestDiscountRatioCache[game.appId];
      if (ratio != null && game.initialPrice != null && game.initialPrice! > 0) {
        final calcLow = currencyCode == 'USD'
            ? (game.initialPrice! * ratio)
            : (game.initialPrice! * ratio).round();
        game.lowestPrice = calcLow;
      } else {
        // Fallback an toàn: giá sale hiện tại hoặc giá gốc
        game.lowestPrice = game.finalPrice ?? game.initialPrice ?? 0;
      }
      game.lowestPriceFormatted =
          _formatAmount(game.lowestPrice!, currencyCode);
    }
  }

  /// Tính toán số liệu thống kê thư viện giống hệt calculateLibraryStats trong steam-api-test
  static SteamLibraryStats _calculateLibraryStats({
    required List<SteamGameItem> games,
    int? totalGamesCount,
    required String currencyCode,
    required bool hasApiKey,
  }) {
    double totalPlaytimeHours = 0.0;
    num totalInitialPrice = 0;
    num totalCurrentPrice = 0;
    num totalLowestPrice = 0;
    int calculatedCount = 0;

    for (final game in games) {
      totalPlaytimeHours += game.playtimeHours;
      if (game.initialPrice != null) {
        totalInitialPrice += game.initialPrice!;
      }
      if (game.finalPrice != null) {
        totalCurrentPrice += game.finalPrice!;
      }
      if (game.lowestPrice != null) {
        totalLowestPrice += game.lowestPrice!;
      } else {
        totalLowestPrice += (game.finalPrice ?? game.initialPrice ?? 0);
      }
      calculatedCount++;
    }

    totalPlaytimeHours = ((totalPlaytimeHours * 10).round()) / 10.0;
    final totalPlaytimeDays = ((totalPlaytimeHours / 24.0) * 10).round() / 10.0;

    final initialFormatted = _formatAmount(totalInitialPrice, currencyCode);
    final currentFormatted = _formatAmount(totalCurrentPrice, currencyCode);
    final lowestFormatted = _formatAmount(totalLowestPrice, currencyCode);

    final resolvedTotalGames = (totalGamesCount != null && totalGamesCount > 0)
        ? totalGamesCount
        : games.length;

    // Chi phí trên mỗi giờ chơi: Price / hour
    String costPerHour;
    if (totalPlaytimeHours > 0 && totalCurrentPrice > 0) {
      if (currencyCode == 'USD') {
        final cph = totalCurrentPrice / totalPlaytimeHours;
        costPerHour = '\$${cph.toStringAsFixed(2)}/h';
      } else {
        final cph = (totalCurrentPrice / totalPlaytimeHours).round();
        costPerHour = '${_formatVnd(cph)}/h';
      }
    } else {
      costPerHour = currencyCode == 'USD' ? '\$0.00/h' : '0 ₫/h';
    }

    final note = hasApiKey
        ? 'Full data from Steam Web API (including entire game library and Steam Store prices).'
        : 'Statistical data based on publicly available games from the Steam profile. Configure a Steam API Key to scan 100% of your library.';

    return SteamLibraryStats(
      totalGamesCount: resolvedTotalGames,
      totalPlaytimeHours: totalPlaytimeHours,
      totalPlaytimeDays: totalPlaytimeDays,
      totalInitialPrice: totalInitialPrice,
      totalCurrentPrice: totalCurrentPrice,
      totalLowestPrice: totalLowestPrice,
      totalInitialPriceFormatted: initialFormatted,
      totalCurrentPriceFormatted: currentFormatted,
      totalLowestPriceFormatted: lowestFormatted,
      currency: currencyCode,
      costPerHour: costPerHour,
      gamesCountCalculated: calculatedCount,
      note: note,
    );
  }

  static String _formatAmount(num amount, String currencyCode) =>
      SteamFormatters.formatAmount(amount, currencyCode);

  static String _formatVnd(num amount) => SteamFormatters.formatVnd(amount);

  static final Map<String, Uint8List> _imageCache = {};

  /// Tải dữ liệu ảnh thông qua DoH + SNI socket (bỏ qua chặn DNS của nhà mạng VN)
  static Future<Uint8List?> fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (_imageCache.containsKey(trimmed)) return _imageCache[trimmed];
    try {
      final bytes = await httpGetBytes(trimmed);
      if (bytes.isNotEmpty) {
        _imageCache[trimmed] = bytes;
        return bytes;
      }
    } catch (_) {}
    return null;
  }

  /// Request HTTP GET lấy raw bytes cho hình ảnh, fallback DoH tự động
  static Future<Uint8List> httpGetBytes(String urlString) async {
    final uri = Uri.parse(urlString);

    // 1. Thử HttpClient chuẩn trước
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      client.badCertificateCallback = (cert, host, port) => true;
      final req = await client.getUrl(uri);
      req.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );
      final res = await req.close();
      if (res.statusCode == 301 || res.statusCode == 302) {
        final loc = res.headers.value('location');
        client.close();
        if (loc != null && loc.isNotEmpty) {
          return await httpGetBytes(uri.resolve(loc).toString());
        }
      }
      final builder = BytesBuilder();
      await for (final chunk in res) {
        builder.add(chunk);
      }
      client.close();
      final bytes = builder.toBytes();
      if (bytes.isNotEmpty) return bytes;
    } catch (_) {}

    // 2. DoH + Socket fallback cho người dùng không bật 1.1.1.1
    final ips = await _resolveHostAllIps(uri.host);
    if (ips.isEmpty) throw Exception('Không thể phân giải: ${uri.host}');

    for (final ip in ips) {
      try {
        final port = uri.hasPort ? uri.port : 443;
        final rawSocket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(seconds: 4),
        );
        Socket socket = rawSocket;
        if (uri.scheme == 'https') {
          socket = await SecureSocket.secure(
            rawSocket,
            host: uri.host,
            onBadCertificate: (cert) => true,
          );
        }

        final path = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
        final request = 'GET $path HTTP/1.1\r\n'
            'Host: ${uri.host}\r\n'
            'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36\r\n'
            'Connection: close\r\n\r\n';

        socket.write(request);
        await socket.flush();

        final builder = BytesBuilder();
        await for (final chunk in socket) {
          builder.add(chunk);
        }
        await socket.close();

        final rawData = builder.toBytes();
        for (int i = 0; i < rawData.length - 3; i++) {
          if (rawData[i] == 13 &&
              rawData[i + 1] == 10 &&
              rawData[i + 2] == 13 &&
              rawData[i + 3] == 10) {
            final headerStr =
                utf8.decode(rawData.sublist(0, i), allowMalformed: true);
            if (headerStr.contains('301') || headerStr.contains('302')) {
              final locMatch = RegExp(
                r'Location:\s*([^\r\n]+)',
                caseSensitive: false,
              ).firstMatch(headerStr);
              if (locMatch != null) {
                return await httpGetBytes(
                  uri.resolve(locMatch.group(1)!.trim()).toString(),
                );
              }
            }
            return rawData.sublist(i + 4);
          }
        }
      } catch (_) {}
    }

    throw Exception('Không thể tải hình ảnh từ ${uri.host}');
  }
}
