import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:let_note/main.dart';

void main() {
  testWidgets('LetNoteApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LetNoteApp(),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify app renders
    expect(find.byType(LetNoteApp), findsOneWidget);
  });
}
