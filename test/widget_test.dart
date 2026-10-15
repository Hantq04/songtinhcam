import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songtinhcam/main.dart';
import 'package:songtinhcam/models/steam_models.dart';
import 'package:songtinhcam/screens/steam_result_screen.dart';

void main() {
  testWidgets('Steam Calculator smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SteamApp());

    // Verify that the title is rendered.
    expect(find.text('Steam Calculator'), findsOneWidget);
    expect(find.text('Your profile url or steamid'), findsOneWidget);
    expect(find.text('Get disappointed in your life'), findsOneWidget);
  });

  testWidgets('SteamResultScreen renders Account Value correctly on mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const result = SteamCalculationResult(
      profileName: 'FahnarT',
      steamId: '76561199168000000',
      steamLevel: 23,
      badgesCount: 21,
      realName: 'Quang Hà',
      totalValue: '10.551.500 ₫',
      lowestPrice: '10.551.500 ₫',
      gamesOwned: 187,
      hoursPlayed: '1.200h',
      pricePerHour: '8.790 ₫/h',
      vacStatus: 'Normal',
      games: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SteamResultScreen(
          result: result,
          currencyName: 'VND',
        ),
      ),
    );

    expect(find.text('Account Value'), findsOneWidget);
    expect(find.text('10.551.500 ₫'), findsWidgets);
    expect(find.text('FahnarT'), findsOneWidget);
  });
}
