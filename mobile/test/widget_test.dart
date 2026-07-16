import 'package:flutter_test/flutter_test.dart';
import 'package:lowpoly/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LowpolyApp());
    expect(find.byType(LowpolyApp), findsOneWidget);
  });
}
