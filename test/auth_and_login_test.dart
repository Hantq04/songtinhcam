import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songtinhcam/main.dart';
import 'package:songtinhcam/screens/login_screen.dart';
import 'package:songtinhcam/services/auth_service.dart';

void main() {
  setUp(() {
    AuthService.instance.signOut();
  });

  testWidgets('TopNavBar hides Menu button on CalculatorScreen and shows Backup/Login in user dropdown',
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

    // Verify 'Backup' and 'Login' options are displayed
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Selecting Login opens LoginScreen with only "Login with email" button and no manual text input',
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
}
