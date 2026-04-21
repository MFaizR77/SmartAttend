import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAttendApp());

    // Verify login screen is shown
    expect(find.text('SmartAttend'), findsOneWidget);
    expect(find.text('Masuk'), findsAny);
  });
}
