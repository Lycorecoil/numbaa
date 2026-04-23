import 'package:flutter_test/flutter_test.dart';
import 'package:numbia/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const NumbiaApp());
    // Verify splash screen renders
    expect(find.text('NUMBIA'), findsOneWidget);
  });
}
