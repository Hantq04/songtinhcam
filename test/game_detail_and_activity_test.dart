import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:songtinhcam/models/steam_models.dart';
import 'package:songtinhcam/screens/steam_game_detail_screen.dart';
import 'package:songtinhcam/services/database_service.dart';

void main() {
  Database? testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 4,
      onCreate: (db, version) async {
        await DatabaseService.createTables(db);
      },
    );
    DatabaseService.instance.setDatabaseForTesting(testDb);
  });

  tearDown(() {
    DatabaseService.instance.setDatabaseForTesting(null);
  });

  group('GameActivity and SteamGameItem models', () {
    test('GameActivity serializes and deserializes correctly', () {
      final now = DateTime(2026, 10, 14, 8, 30);
      final activity = GameActivity(
        steamId: '76561198006889896',
        appId: 730,
        playtimeHours: 2.0,
        loggedAt: now,
        userName: 'Ngô Trần Quang Hà',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final map = activity.toMap();
      expect(map['steam_id'], '76561198006889896');
      expect(map['app_id'], 730);
      expect(map['playtime_hours'], 2.0);
      expect(map['logged_at'], now.millisecondsSinceEpoch);
      expect(map['user_name'], 'Ngô Trần Quang Hà');

      final fromMap = GameActivity.fromMap(map);
      expect(fromMap.steamId, activity.steamId);
      expect(fromMap.appId, activity.appId);
      expect(fromMap.playtimeHours, activity.playtimeHours);
      expect(
        fromMap.loggedAt.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
      expect(fromMap.userName, activity.userName);
    });

    test('SteamGameItem serializes startDate correctly', () {
      final start = DateTime(2026, 10, 21, 14, 0);
      final game = SteamGameItem(
        appId: 10,
        name: 'Counter-Strike',
        playtimeHours: 12.5,
        storeUrl: 'https://store.steampowered.com/app/10',
        startDate: start,
        status: 'InProgress',
      );

      final map = game.toMap();
      expect(map['startDate'], start.toIso8601String());
      expect(map['status'], 'InProgress');
    });
  });

  group('DatabaseService game status and activity operations', () {
    test(
      'saveGameStatus saves status and auto sets start_date on InProgress',
      () async {
        const steamId = '76561198001122334';
        const appId = 570;

        // 1. Initial status Affectionless
        await DatabaseService.instance.saveGameStatus(
          steamId: steamId,
          appId: appId,
          status: 'Affectionless',
        );

        var state = await DatabaseService.instance.getGameStatus(
          steamId: steamId,
          appId: appId,
        );
        expect(state, isNotNull);
        expect(state!['status'], 'Affectionless');
        expect(state['start_date'], isNull);

        // 2. Change status to InProgress -> start_date is automatically set
        final beforeTime = DateTime.now().millisecondsSinceEpoch - 50;
        await DatabaseService.instance.saveGameStatus(
          steamId: steamId,
          appId: appId,
          status: 'InProgress',
        );
        final afterTime = DateTime.now().millisecondsSinceEpoch + 50;

        state = await DatabaseService.instance.getGameStatus(
          steamId: steamId,
          appId: appId,
        );
        expect(state!['status'], 'InProgress');
        expect(state['start_date'], isNotNull);
        final startDate = state['start_date'] as int;
        expect(startDate >= beforeTime && startDate <= afterTime, isTrue);

        // 3. Change status to Done -> start_date is preserved
        await DatabaseService.instance.saveGameStatus(
          steamId: steamId,
          appId: appId,
          status: 'Done',
        );

        state = await DatabaseService.instance.getGameStatus(
          steamId: steamId,
          appId: appId,
        );
        expect(state!['status'], 'Done');
        expect(state['start_date'], startDate);
      },
    );

    test('syncGamePlaytimes computes delta = newlySynced - savedPlaytime and logs activity', () async {
      const steamId = '76561198001122334';
      final game = SteamGameItem(
        appId: 730,
        name: 'CS2',
        playtimeHours: 10.0,
        storeUrl: 'https://store.steampowered.com/app/730',
      );

      // 1. First sync: baseline recorded (10.0h)
      await DatabaseService.instance.syncGamePlaytimes(
        steamId: steamId,
        games: [game],
        userName: 'Ngô Trần Quang Hà',
      );

      var activities = await DatabaseService.instance.getGameActivities(
        steamId: steamId,
        appId: 730,
      );
      expect(activities.length, 1);
      expect(activities.first.playtimeHours, 10.0);
      expect(activities.first.userName, 'Ngô Trần Quang Hà');

      // 2. Second sync with NO playtime change (still 10.0h)
      await DatabaseService.instance.syncGamePlaytimes(
        steamId: steamId,
        games: [game],
        userName: 'Ngô Trần Quang Hà',
      );

      activities = await DatabaseService.instance.getGameActivities(
        steamId: steamId,
        appId: 730,
      );
      // No duplicate activity added
      expect(activities.length, 1);

      // 3. User plays 2 hours more on Steam -> new synced playtime is 12.0h
      game.playtimeHours = 12.0;
      await DatabaseService.instance.syncGamePlaytimes(
        steamId: steamId,
        games: [game],
        userName: 'Ngô Trần Quang Hà',
      );

      activities = await DatabaseService.instance.getGameActivities(
        steamId: steamId,
        appId: 730,
      );
      expect(activities.length, 2);
      // The newest activity logged is delta: 12.0 - 10.0 = 2.0h!
      expect(activities.first.playtimeHours, 2.0);
      expect(activities.first.userName, 'Ngô Trần Quang Hà');

      // Verify saved state in SQLite was updated to 12.0
      final state = await DatabaseService.instance.getGameStatus(
        steamId: steamId,
        appId: 730,
      );
      expect((state!['saved_playtime'] as num).toDouble(), 12.0);
    });
  });

  group('SteamGameDetailScreen UI tests', () {
    testWidgets('displays Activity and does NOT have the 4 sub-tabs', (
      tester,
    ) async {
      const steamId = '76561198009988776';
      final game = SteamGameItem(
        appId: 2835570,
        name: 'Buckshot Roulette',
        playtimeHours: 2.0,
        storeUrl: 'https://store.steampowered.com/app/2835570',
        status: 'Affectionless',
      );

      await tester.runAsync(() async {
        await DatabaseService.instance.addGameActivity(
          GameActivity(
            steamId: steamId,
            appId: 2835570,
            playtimeHours: 2.0,
            loggedAt: DateTime(2026, 10, 14, 8, 30),
            userName: 'Ngô Trần Quang Hà',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SteamGameDetailScreen(
              game: game,
              currencyName: 'Vietnamese Dong',
              profileName: 'Ngô Trần Quang Hà',
              steamId: steamId,
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // 1. Verify Activity section exists
      expect(find.text('Activity'), findsWidgets);

      // 2. Verify the 4 sub-tabs are removed
      expect(find.text('All'), findsNothing);
      expect(find.text('Comments'), findsNothing);
      expect(find.text('History'), findsNothing);
      expect(find.text('Work log'), findsNothing);
      expect(find.text('Add a comment...'), findsNothing);

      // 3. Verify Activity item is rendered with user initials, name, and logged 2h
      expect(find.text('NH'), findsOneWidget);
      expect(find.textContaining('Ngô Trần Quang Hà'), findsWidgets);
      expect(find.textContaining('logged'), findsOneWidget);
      expect(find.textContaining('2h'), findsWidgets);
      expect(
        find.textContaining('October 14, 2026 at 8:30 AM'),
        findsOneWidget,
      );
    });
  });
}
