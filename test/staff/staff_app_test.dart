import 'package:flutter_test/flutter_test.dart';

import '../support/desk_driver.dart';

void main() {
  testWidgets('the front desk app starts on sign-in', (tester) async {
    await startDesk(tester);

    expect(find.text('Volt Desk'), findsOneWidget);
    expect(find.text('Sign in to the front desk'), findsOneWidget);
  });
}
