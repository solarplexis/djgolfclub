import 'package:flutter_test/flutter_test.dart';
import 'package:djgolfcard/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DJGolfCardApp());
    expect(find.byType(DJGolfCardApp), findsOneWidget);
  });
}
