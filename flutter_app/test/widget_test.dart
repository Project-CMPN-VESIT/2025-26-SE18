import 'package:flutter_test/flutter_test.dart';
import 'package:ngo_education_platform/main.dart';

void main() {
  testWidgets('App starts and shows login', (WidgetTester tester) async {
    await tester.pumpWidget(const NGOEducationApp());
    await tester.pumpAndSettle();
    expect(find.text('Education Platform'), findsOneWidget);
  });
}
