import 'package:flutter_test/flutter_test.dart';
import 'package:songtinhcam/services/steam_service.dart';
import 'package:songtinhcam/utils/steam_formatters.dart';

void main() {
  group('SteamService buildSteamXmlUrl tests', () {
    test('handles standard 17-digit steamId64', () {
      final url = SteamService.buildSteamXmlUrl('76561198006889896');
      expect(url, 'https://steamcommunity.com/profiles/76561198006889896/?xml=1');
    });

    test('handles profile url with trailing slash', () {
      final url = SteamService.buildSteamXmlUrl('https://steamcommunity.com/profiles/76561198006889896/');
      expect(url, 'https://steamcommunity.com/profiles/76561198006889896/?xml=1');
    });

    test('handles vanity customURL', () {
      final url = SteamService.buildSteamXmlUrl('https://steamcommunity.com/id/gabelogannewell');
      expect(url, 'https://steamcommunity.com/id/gabelogannewell/?xml=1');
    });

    test('handles plain vanity slug', () {
      final url = SteamService.buildSteamXmlUrl('gabelogannewell');
      expect(url, 'https://steamcommunity.com/id/gabelogannewell/?xml=1');
    });

    test('handles SteamID3 format [U:1:1208333168]', () {
      final url = SteamService.buildSteamXmlUrl('[U:1:1208333168]');
      expect(url, contains('/profiles/'));
      expect(url, endsWith('/?xml=1'));
    });
  });

  group('SteamGameItem model tests', () {
    test('serializes to map correctly with lowestPrice', () {
      final item = SteamGameItem(
        appId: 2835570,
        name: 'Buckshot Roulette',
        playtimeHours: 44.0,
        storeUrl: 'https://store.steampowered.com/app/2835570',
        initialPrice: 45000,
        finalPrice: 45000,
        lowestPrice: 22500,
        initialPriceFormatted: '45.000 ₫',
        finalPriceFormatted: '45.000 ₫',
        lowestPriceFormatted: '22.500 ₫',
        discountPercent: 0,
        isFree: false,
      );

      final map = item.toMap();
      expect(map['appId'], 2835570);
      expect(map['name'], 'Buckshot Roulette');
      expect(map['finalPriceFormatted'], '45.000 ₫');
      expect(map['lowestPriceFormatted'], '22.500 ₫');
      expect(map['lowestPrice'], 22500);
      expect(map['isFree'], false);
    });
  });

  group('SteamLibraryStats and SteamCalculationResult tests', () {
    test('SteamLibraryStats stores and serializes totalLowestPrice', () {
      final stats = SteamLibraryStats(
        totalGamesCount: 187,
        totalInitialPrice: 10551500,
        totalCurrentPrice: 8725000,
        totalLowestPrice: 4500000,
        totalInitialPriceFormatted: '10.551.500 ₫',
        totalCurrentPriceFormatted: '8.725.000 ₫',
        totalLowestPriceFormatted: '4.500.000 ₫',
      );

      final map = stats.toMap();
      expect(map['totalLowestPrice'], 4500000);
      expect(map['totalLowestPriceFormatted'], '4.500.000 ₫');
      expect(map['totalCurrentPriceFormatted'], '8.725.000 ₫');
    });

    test('SteamCalculationResult supports totalValue as lowest price and todayPrice', () {
      const result = SteamCalculationResult(
        profileName: 'FahnarT',
        steamId: '76561199168598896',
        steamLevel: 23,
        totalValue: '4.500.000 ₫',
        todayPrice: '8.725.000 ₫',
        lowestPrice: '8.725.000 ₫',
        gamesOwned: 187,
        hoursPlayed: '1500h',
        pricePerHour: '5.572 ₫/h',
        vacStatus: 'In good standing',
      );

      expect(result.totalValue, '4.500.000 ₫');
      expect(result.todayPrice, '8.725.000 ₫');
      final map = result.toMap();
      expect(map['todayPrice'], '8.725.000 ₫');
      expect(map['totalValue'], '4.500.000 ₫');
    });
  });

  group('SteamFormatters tests', () {
    test('formats VND currency with thousand separator dots and ₫', () {
      expect(SteamFormatters.formatVnd(140000), '140.000 ₫');
      expect(SteamFormatters.formatVnd(0), '0 ₫');
      expect(SteamFormatters.formatVnd(1234567), '1.234.567 ₫');
    });

    test('formats USD currency correctly', () {
      expect(SteamFormatters.formatUsd(19.99), '\$19.99');
      expect(SteamFormatters.formatUsd(0), '\$0.00');
    });

    test('formats price per hour correctly', () {
      expect(SteamFormatters.formatPricePerHour(15000, 'VND'), '15.000 ₫/h');
      expect(SteamFormatters.formatPricePerHour(1.25, 'USD'), '\$1.25/h');
    });

    test('formats minutes to hours', () {
      expect(SteamFormatters.formatMinutesToHours(120), '2h');
      expect(SteamFormatters.formatMinutesToHours(60000), '1,000h');
    });

    test('calculateAccount for 76561199168598896 retrieves games with defaultApiKey', () async {
      // ignore: avoid_print
      print('defaultApiKey in test: "${SteamService.defaultApiKey}"');
      final result = await SteamService.calculateAccount(
        input: '76561199168598896',
        currencyName: 'Vietnamese Dong',
      );
      // ignore: avoid_print
      print('Profile: ${result.profileName}, games: ${result.games.length}, totalValue: ${result.totalValue}, todayPrice: ${result.todayPrice}');
      expect(result.profileName, 'FahnarT');
      expect(result.games.isNotEmpty, true);
      expect(result.totalValue, isNot('N/A'));
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}

