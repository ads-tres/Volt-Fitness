import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/photos/photo_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../support/desk_driver.dart';
import '../support/fake_photo_picker.dart';

void main() {
  Future<void> searchFor(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  Future<void> findAbebe(WidgetTester tester) async {
    await openScanner(tester);
    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await searchFor(tester, 'abe');
  }

  Future<void> openPhotoSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('member-photo-1')));
    await tester.pumpAndSettle();
  }

  testWidgets('the desk takes a member\'s photo, sees it on the result and Today, and removes it', (tester) async {
    await startDesk(tester, extraOverrides: [photoPickerProvider.overrideWithValue(FakePicker())]);
    await findAbebe(tester);
    expect(find.byKey(const Key('member-photo')), findsNothing);
    expect(find.text('AK'), findsOneWidget, reason: 'initials until there is a photo');

    await openPhotoSheet(tester);
    expect(find.text('Remove photo'), findsNothing);
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.text("Abebe Kebede's photo is saved."), findsOneWidget);
    expect(find.byKey(const Key('member-photo')), findsOneWidget);

    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    expect(find.text('Let in'), findsOneWidget);
    expect(find.byKey(const Key('member-photo')), findsWidgets, reason: 'large on the result');
    await tester.tap(find.byKey(const Key('check-in-result')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('member-photo')), findsNWidgets(2), reason: 'on both of Abebe\'s rows');

    await tester.tap(find.text('Desk'));
    await tester.pumpAndSettle();
    await searchFor(tester, 'abe');
    await openPhotoSheet(tester);
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.text("Abebe Kebede's photo is removed."), findsOneWidget);
    expect(find.byKey(const Key('member-photo')), findsNothing);
  });

  testWidgets('a photo the API refuses shows its reason', (tester) async {
    final tooBig = List<int>.filled(5 * 1024 * 1024 + 1, 0);
    await startDesk(tester, extraOverrides: [photoPickerProvider.overrideWithValue(FakePicker(bytes: tooBig))]);
    await findAbebe(tester);

    await openPhotoSheet(tester);
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text('The photo may not be bigger than 5 MB.'), findsOneWidget);
    expect(find.byKey(const Key('member-photo')), findsNothing);
  });
}
