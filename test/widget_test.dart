import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:smartattend/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    final authViewModel = AuthViewModel();
    addTearDown(authViewModel.dispose);

    await tester.pumpWidget(
      SmartAttendApp(
        authViewModel: authViewModel,
        initialRoute: '/login',
      ),
    );
    await tester.pump();

    // Verify login screen is shown
    expect(find.text('SmartAttend'), findsAny);
    expect(find.text('Masuk'), findsAny);
  });
}
