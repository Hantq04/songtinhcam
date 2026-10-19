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

  tearDown(() async {
    await testDb?.close();
    DatabaseService.instance.setDatabaseForTesting(null);
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

    // Enter Steam ID in Dialog
    final steamIdField = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    expect(steamIdField, findsOneWidget);
    await tester.enterText(steamIdField, '76561199168598896');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify saved to SQLite
    final savedId = await DatabaseService.instance.getSavedSteamId('test.steam@gmail.com');
    expect(savedId, '76561199168598896');
  });
}
