import 'package:flutter_test/flutter_test.dart';
import 'package:osama_phone/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OsamaPhoneApp());
    expect(find.byType(OsamaPhoneApp), findsOneWidget);
  });
}
