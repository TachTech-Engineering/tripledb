import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TripleDBApp()));

    // Verify that our app shows the title
    expect(find.text('TripleDB'), findsOneWidget);
  });
}
