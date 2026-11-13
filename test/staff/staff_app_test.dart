import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/staff/app/staff_app.dart';

import '../support/test_doubles.dart';

void main() {
  testWidgets('the front desk app starts', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: await testOverrides(), child: const StaffApp()));
    await tester.pumpAndSettle();

    expect(find.text('Volt Desk'), findsOneWidget);
  });
}
