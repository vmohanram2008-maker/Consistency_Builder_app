import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:consistency_builder/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app opens the direct-start workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const ConsistencyBuilderApp());
    await tester.pumpAndSettle();

    expect(find.text('Consistency Builder'), findsOneWidget);
    expect(find.text('Your consistency workspace'), findsOneWidget);
    expect(find.text('Build the day you want.'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Achievement'), findsOneWidget);
  });
}
