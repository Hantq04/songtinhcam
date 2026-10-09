import 'package:flutter_test/flutter_test.dart';
import 'package:songtinhcam/main.dart';

void main() {
  testWidgets('Steam Calculator smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SteamApp());

    // Verify that the title is rendered.
    expect(find.text('Steam Calculator'), findsOneWidget);
    expect(find.text('Your profile url or steamid'), findsOneWidget);
    expect(find.text('Steam Web API Key (apiKey)'), findsOneWidget);
  });
}
