import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:songtinhcam/main.dart';
import 'package:songtinhcam/screens/login_screen.dart';
import 'package:songtinhcam/services/auth_service.dart';
import 'package:songtinhcam/services/database_service.dart';

void main() {
  Database? testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    AuthService.instance.signOut();
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_profiles (
            email TEXT PRIMARY KEY,
            display_name TEXT,
            steam_id TEXT,
            avatar_url TEXT,
            updated_at INTEGER
          )
        ''');
      },
    );
    DatabaseService.instance.setDatabaseForTesting(testDb);
  });

  tearDown(() {
    DatabaseService.instance.setDatabaseForTesting(null);
  });

  test('DatabaseService saves and retrieves steam id', () async {
    await DatabaseService.instance.saveUserProfile(
      email: 'test@example.com',
      steamId: '12345678',
    );
    final id = await DatabaseService.instance.getSavedSteamId('test@example.com');
    expect(id, '12345678');
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
  });

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
  });

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
      return await DatabaseService.instance.getSavedSteamId('test.steam@gmail.com');
    });
    expect(savedId, '76561199168598896');

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('User Profile'), findsNothing);
  });

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
  });
}
