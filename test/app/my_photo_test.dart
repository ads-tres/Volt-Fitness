import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/features/profile/data/my_photo.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_driver.dart';

/// Stands in for the camera and gallery: hands over a 1×1 picture.
final class FakePicker implements PhotoPicker {
  static final picture = base64.decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  Future<PickedPhoto?> take() async => (bytes: picture, name: 'camera.png');

  @override
  Future<PickedPhoto?> choose() async => (bytes: picture, name: 'gallery.png');
}

void main() {
  testWidgets('a member takes a photo for their profile and QR screen, and removes it', (tester) async {
    await startApp(tester, extraOverrides: [photoPickerProvider.overrideWithValue(FakePicker())]);
    await signInWith(tester, phone: '0912345678');
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('member-photo')), findsNothing);
    expect(find.text('AK'), findsOneWidget, reason: 'initials until there is a photo');

    await tester.tap(find.byKey(const Key('my-photo')));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo'), findsNothing);
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text('Your photo is saved.'), findsOneWidget);
    expect(find.byKey(const Key('member-photo')), findsOneWidget);

    await tester.tap(find.byTooltip('My QR'));
    await pumpFor(tester);
    expect(find.byKey(const Key('member-photo')), findsOneWidget, reason: 'on the QR screen too');

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('my-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    expect(find.text('Your photo is removed.'), findsOneWidget);
    expect(find.byKey(const Key('member-photo')), findsNothing);
  });
}
