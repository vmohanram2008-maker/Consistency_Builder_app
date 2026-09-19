import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:consistency_builder/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app does not show a login gate on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const ConsistencyBuilderApp());
    await tester.pumpAndSettle();

    expect(find.text('Consistency Builder'), findsOneWidget);
    expect(find.text('Your consistency workspace'), findsOneWidget);
    expect(find.byType(MainNavigationShell), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Register'), findsNothing);
  });
}
