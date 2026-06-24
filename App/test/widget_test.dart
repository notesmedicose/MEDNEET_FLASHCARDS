import 'package:flutter_test/flutter_test.dart';
import 'package:mednotes/main.dart';
import 'package:mednotes/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    AuthProvider.testMode = true;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MedNotesApp());

    // Verify that Splash Screen is shown with app title
    expect(find.text('MEDNEET'), findsOneWidget);
    expect(find.text('Flashcards • QBank • Notes'), findsOneWidget);

    // Let the splash screen timer finish and settle
    await tester.pump(const Duration(seconds: 4));
  });
}
