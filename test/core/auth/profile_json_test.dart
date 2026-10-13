import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/auth/profile_json.dart';

void main() {
  final apiJson = {
    'user': {'id': 'u1', 'name': 'Abebe Kebede', 'phone': '+251911234567'},
    'organizations': [
      {
        'id': 'o1',
        'name': 'Bole Iron Gym',
        'role': 'member',
        'branding': {'logo_url': null, 'primary_color': '#0E7C66', 'accent_color': 'teal', 'contact_phone': null},
        'features': ['classes', 42],
        'added_later': true,
      },
    ],
  };

  test('reads the API shape, ignoring unknown fields and bad values', () {
    final profile = profileFromJson(apiJson);

    expect(profile.user.firstName, 'Abebe');
    final gym = profile.organizations.single;
    expect(gym.branding.primaryColor, const Color(0xFF0E7C66));
    expect(gym.branding.accentColor, isNull, reason: 'not #RRGGBB');
    expect(gym.features, {'classes'});
  });

  test('survives a round trip through the cache', () {
    final profile = profileFromJson(apiJson);
    final again = profileFromJson(profileToJson(profile));

    expect(again.organizations.single.branding.primaryColor, profile.organizations.single.branding.primaryColor);
    expect(again.user.phone, profile.user.phone);
  });

  test('rejects a profile without a user', () {
    expect(() => profileFromJson({'organizations': <Object?>[]}), throwsFormatException);
  });
}
