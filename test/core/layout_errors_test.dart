import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/layout_errors.dart';

void main() {
  testWidgets('catches text that overflows, so the tours can\'t pass blind', (tester) async {
    final errors = LayoutErrors()..screen = 'a narrow row';
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 50,
          child: Row(children: [Text('This line is far too long to fit in fifty pixels')]),
        ),
      ),
    );
    expect(errors.found, isNotEmpty);
    expect(errors.found.first, startsWith('a narrow row: A RenderFlex overflowed'));
  });
}
