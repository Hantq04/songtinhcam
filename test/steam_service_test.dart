import 'package:flutter_test/flutter_test.dart';
import 'package:songtinhcam/services/steam_service.dart';

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
    test('serializes to map correctly', () {
      final item = SteamGameItem(
        appId: 2835570,
        name: 'Buckshot Roulette',
        playtimeHours: 44.0,
        storeUrl: 'https://store.steampowered.com/app/2835570',
        initialPrice: 45000,
        finalPrice: 45000,
        initialPriceFormatted: '45.000 ₫',
        finalPriceFormatted: '45.000 ₫',
        discountPercent: 0,
        isFree: false,
      );

      final map = item.toMap();
      expect(map['appId'], 2835570);
      expect(map['name'], 'Buckshot Roulette');
      expect(map['finalPriceFormatted'], '45.000 ₫');
      expect(map['isFree'], false);
    });
  });
}
