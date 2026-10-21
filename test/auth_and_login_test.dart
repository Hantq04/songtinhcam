import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:songtinhcam/main.dart';
import 'package:songtinhcam/models/steam_models.dart';
import 'package:songtinhcam/screens/login_screen.dart';
import 'package:songtinhcam/screens/steam_all_games_screen.dart';
import 'package:songtinhcam/services/auth_service.dart';
import 'package:songtinhcam/services/database_service.dart';
import 'package:songtinhcam/services/env_service.dart';

void main() {
  Database? testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 3,
      onCreate: (db, version) async {
        await DatabaseService.createTables(db);
      },
    );
    DatabaseService.instance.setDatabaseForTesting(testDb);
    await AuthService.instance.signOut();
  });

  tearDown(() {
    DatabaseService.instance.setDatabaseForTesting(null);
  });

  test(
    'EnvService resolves candidate paths and loads env variables properly',
    () async {
      // 1. Verify candidatePaths contains relative .env directories
      expect(EnvService.candidatePaths, contains('.env'));
      expect(EnvService.candidatePaths, contains('../.env'));

      // 2. Test reading STEAM_API_KEY from .env
      final steamKey = await EnvService.getSteamApiKey();
      expect(steamKey, isNotEmpty);
      expect(steamKey, 'C9044A348D1995C8554630126B261E6B');

      // 3. Test reading defaultSteamApiKey sync
      final syncSteamKey = EnvService.defaultSteamApiKey;
      expect(syncSteamKey, 'C9044A348D1995C8554630126B261E6B');

      // 4. Test reading GOOGLE_CLIENT_ID from .env
      final googleId = await EnvService.getGoogleClientId();
      expect(googleId, isNotNull);
      expect(
        googleId,
        contains('27263971300-jrf7u0hop04bumpk3flg0e5k2rutvf9u'),
      );

      // 5. Test setForTesting and resetForTesting
      EnvService.setForTesting('TEST_KEY', 'test_value_123');
      expect(EnvService.getSync('TEST_KEY'), 'test_value_123');
      EnvService.resetForTesting();
    },
  );

  test('DatabaseService saves, retrieves, and clears active_session', () async {
    // 1. Initially no active session
    var session = await DatabaseService.instance.getActiveSession();
    expect(session, isNull);

    // 2. Save active session
    await DatabaseService.instance.saveActiveSession(
      email: 'gamer.real@gmail.com',
      displayName: 'Real Gamer',
      avatarUrl: 'https://example.com/avatar.png',
    );

    // 3. Retrieve active session
    session = await DatabaseService.instance.getActiveSession();
    expect(session, isNotNull);
    expect(session!['email'], 'gamer.real@gmail.com');
    expect(session['display_name'], 'Real Gamer');
    expect(session['avatar_url'], 'https://example.com/avatar.png');

    // 4. Clear active session (on logout)
    await DatabaseService.instance.clearActiveSession();
    session = await DatabaseService.instance.getActiveSession();
    expect(session, isNull);
  });

  test(
    'AuthService persists session across app re-initialization until signOut',
    () async {
      // User logs in
      await AuthService.instance.setLoggedInUser(
        email: 'persistent.gamer@gmail.com',
        displayName: 'Persistent Gamer',
        avatarUrl: 'https://example.com/p.jpg',
      );
      expect(AuthService.instance.isLoggedIn, true);

      // Verify session stored in SQLite
      final session = await DatabaseService.instance.getActiveSession();
      expect(session, isNotNull);
      expect(session!['email'], 'persistent.gamer@gmail.com');

      // User logs out
      await AuthService.instance.signOut();
      expect(AuthService.instance.isLoggedIn, false);
      final clearedSession = await DatabaseService.instance.getActiveSession();
      expect(clearedSession, isNull);
    },
  );

  test('AuthService.init() restores saved session from SQLite on app startup', () async {
    // 1. Giả lập phiên đăng nhập đã tồn tại trong SQLite từ lần mở app trước
    await DatabaseService.instance.saveActiveSession(
      email: 'reboot.gamer@gmail.com',
      displayName: 'Reboot Gamer',
      avatarUrl: 'https://example.com/avatar.jpg',
    );

    // 2. Giả lập app vừa được mở lại (reset in-memory state)
    AuthService.instance.resetForTesting();
    expect(AuthService.instance.isLoggedIn, false);
    expect(AuthService.instance.userEmail, isNull);

    // 3. main() gọi AuthService.instance.init()
    await AuthService.instance.init();

    // 4. Tài khoản tự động được khôi phục nguyên vẹn mà không bắt đăng nhập lại
    expect(AuthService.instance.isLoggedIn, true);
    expect(AuthService.instance.userEmail, 'reboot.gamer@gmail.com');
    expect(AuthService.instance.userName, 'Reboot Gamer');
    expect(
      AuthService.instance.userAvatarUrl,
      'https://example.com/avatar.jpg',
    );
  });

  test('DatabaseService saves and retrieves steam id', () async {
    await DatabaseService.instance.saveUserProfile(
      email: 'test@example.com',
      steamId: '12345678',
    );
    final id = await DatabaseService.instance.getSavedSteamId(
      'test@example.com',
    );
    expect(id, '12345678');
  });

  test('DatabaseService caches game prices and guarantees lowest price never increases', () async {
    // 1. Lưu giá lần đầu: Game Terraria giá gốc 400.000, đang sale còn 100.000
    await DatabaseService.instance.saveGamePrices([
      {
        'app_id': 105600,
        'currency_code': 'VND',
        'initial_price': 400000,
        'final_price': 100000,
        'lowest_price': 100000,
        'discount_percent': 75,
        'is_free': 0,
      },
    ]);

    // Kiểm tra đã lưu giá 100.000
    var cached = await DatabaseService.instance.getCachedGamePrices(
      appIds: [105600],
      currencyCode: 'VND',
    );
    expect(cached[105600]!['lowest_price'], 100000);
    expect(cached[105600]!['initial_price'], 400000);

    // 2. Đợt sale kết thúc: Steam trả về giá 400.000, CheapShark ko có deal (candidate 400.000)
    await DatabaseService.instance.saveGamePrices([
      {
        'app_id': 105600,
        'currency_code': 'VND',
        'initial_price': 400000,
        'final_price': 400000,
        'lowest_price': 400000, // Giá candidate cao hơn do hết sale
        'discount_percent': 0,
        'is_free': 0,
      },
    ]);

    // Giá đáy trong SQLite VẪN PHẢI LÀ 100.000 (TUYỆT ĐỐI KHÔNG TĂNG LÊN 400.000)
    cached = await DatabaseService.instance.getCachedGamePrices(
      appIds: [105600],
      currencyCode: 'VND',
    );
    expect(cached[105600]!['lowest_price'], 100000);
    expect(cached[105600]!['final_price'], 400000);

    // 3. Đợt sale mới sâu hơn: Giá giảm kỷ lục còn 75.000
    await DatabaseService.instance.saveGamePrices([
      {
        'app_id': 105600,
        'currency_code': 'VND',
        'initial_price': 400000,
        'final_price': 75000,
        'lowest_price': 75000,
        'discount_percent': 81,
        'is_free': 0,
      },
    ]);

    // Giá đáy trong SQLite ĐƯỢC CẬP NHẬT XUỐNG 75.000
    cached = await DatabaseService.instance.getCachedGamePrices(
      appIds: [105600],
      currencyCode: 'VND',
    );
    expect(cached[105600]!['lowest_price'], 75000);
  });

  testWidgets(
    'TopNavBar hides Menu button and shows Profile, Backup, Login in user dropdown',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SteamApp());
      await tester.pumpAndSettle();

      // Verify Menu button is removed
      expect(find.text('Menu'), findsNothing);

      // Verify user profile icon button exists
      final userPillFinder = find.byTooltip('Account & Backup');
      expect(userPillFinder, findsOneWidget);

      // Tap user button to open popup menu
      await tester.tap(userPillFinder);
      await tester.pumpAndSettle();

      // Verify 'Profile', 'Backup' and 'Login' options are displayed
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Backup'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    },
  );

  testWidgets(
    'Selecting Login opens LoginScreen with only "Login with email" button and no manual text input',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SteamApp());
      await tester.pumpAndSettle();

      // Tap user button
      await tester.tap(find.byTooltip('Account & Backup'));
      await tester.pumpAndSettle();

      // Tap 'Login'
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify LoginScreen is shown
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Login to your account'), findsOneWidget);

      // Verify NO text fields exist for manual entry
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);

      // Verify only "Login with email" button exists
      expect(find.text('Login with email'), findsOneWidget);

      // Verify AuthService user updates properly
      AuthService.instance.setLoggedInUser(
        email: 'user.real@gmail.com',
        displayName: 'Real User',
      );
      await tester.pumpAndSettle();

      expect(AuthService.instance.isLoggedIn, true);
      expect(AuthService.instance.userEmail, 'user.real@gmail.com');
    },
  );

  testWidgets(
    'Profile dialog shows user email, name, and saves SteamID to SQLite',
    (WidgetTester tester) async {
      AuthService.instance.setLoggedInUser(
        email: 'test.steam@gmail.com',
        displayName: 'Test Gamer',
      );

      await tester.pumpWidget(const SteamApp());
      await tester.pumpAndSettle();

      // Tap user button
      await tester.tap(find.byTooltip('Account & Backup'));
      await tester.pumpAndSettle();

      // Tap 'Profile'
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify Profile Dialog opened
      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Test Gamer'), findsOneWidget);
      expect(find.text('test.steam@gmail.com'), findsOneWidget);
      expect(find.text('Linked Steam ID'), findsOneWidget);

      // Verify TextField exists for Steam ID
      final steamIdField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      expect(steamIdField, findsOneWidget);

      // Save Steam ID to SQLite and verify via runAsync (FFI isolate)
      await tester.runAsync(() async {
        await DatabaseService.instance.saveUserProfile(
          email: 'test.steam@gmail.com',
          displayName: 'Test Gamer',
          steamId: '76561199168598896',
        );
      });

      final savedId = await tester.runAsync(() async {
        return await DatabaseService.instance.getSavedSteamId(
          'test.steam@gmail.com',
        );
      });
      expect(savedId, '76561199168598896');

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('User Profile'), findsNothing);
    },
  );

  testWidgets(
    'Backup dialog shows Import and Export buttons when user is logged in',
    (WidgetTester tester) async {
      AuthService.instance.setLoggedInUser(
        email: 'backup.tester@gmail.com',
        displayName: 'Backup User',
      );

      await tester.pumpWidget(const SteamApp());
      await tester.pumpAndSettle();

      // Tap Account & Backup menu
      await tester.tap(find.byTooltip('Account & Backup'));
      await tester.pumpAndSettle();

      // Tap Backup menu item
      await tester.tap(find.text('Backup'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Data Backup & Restore'), findsOneWidget);
      expect(find.text('backup.tester@gmail.com'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Tap Close to close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Data Backup & Restore'), findsNothing);
    },
  );

  testWidgets(
    'SteamAllGamesScreen filter button toggles panel and filters games',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleGames = [
        SteamGameItem(
          appId: 1,
          name: 'Alpha Game',
          playtimeHours: 50.0,
          storeUrl: 'https://store.steampowered.com/app/1',
          initialPrice: 200000,
          finalPrice: 200000,
          status: 'Affectionless',
          lastPlayed: DateTime(2026, 1, 10),
        ),
        SteamGameItem(
          appId: 2,
          name: 'Beta Game',
          playtimeHours: 20.0,
          storeUrl: 'https://store.steampowered.com/app/2',
          initialPrice: 500000,
          finalPrice: 500000,
          status: 'InProgress',
          lastPlayed: DateTime(2026, 5, 20),
        ),
        SteamGameItem(
          appId: 3,
          name: 'Gamma Game',
          playtimeHours: 10.0,
          storeUrl: 'https://store.steampowered.com/app/3',
          initialPrice: 0,
          finalPrice: 0,
          isFree: true,
          status: 'Done',
          lastPlayed: DateTime(2026, 9, 15),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SteamAllGamesScreen(
            games: sampleGames,
            currencyName: 'Vietnamese Dong',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify All Games header and Filter button exist
      expect(find.text('All Games in Library'), findsOneWidget);
      expect(find.text('Filter'), findsOneWidget);

      // Tap Filter button to open filter panel
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort Options'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('PRICE & SORTING'), findsOneWidget);
      expect(find.text('DATE RANGE (LAST PLAYED / ACTIVITY)'), findsOneWidget);

      // Tap 'InProgress' chip to filter by InProgress status
      await tester.tap(find.text('InProgress'));
      await tester.pumpAndSettle();

      expect(find.text('Beta Game'), findsOneWidget);
      expect(find.text('Alpha Game'), findsNothing);
      expect(find.text('Gamma Game'), findsNothing);

      // Tap 'Reset' button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Game'), findsOneWidget);
      expect(find.text('Beta Game'), findsOneWidget);
      expect(find.text('Gamma Game'), findsOneWidget);
    },
  );
}
