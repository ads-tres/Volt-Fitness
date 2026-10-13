import 'dart:ui' show Color;

import '../tenant/organization.dart';
import 'profile.dart';

/// Reads the `{user, organizations}` object that both OTP verify and `/me`
/// return. Throws a [FormatException] when required fields are missing.
Profile profileFromJson(Map<String, dynamic> json) => Profile(
  user: _user(_field<Map<String, dynamic>>(json, 'user')),
  organizations: [
    for (final organization in _field<List<dynamic>>(json, 'organizations'))
      if (organization is Map<String, dynamic>) _organization(organization),
  ],
);

/// The same shape back, for caching the profile between app starts.
Map<String, Object?> profileToJson(Profile profile) => {
  'user': {'id': profile.user.id, 'name': profile.user.name, 'phone': profile.user.phone},
  'organizations': [
    for (final organization in profile.organizations)
      {
        'id': organization.id,
        'name': organization.name,
        'role': organization.role,
        'branding': {
          'logo_url': organization.branding.logoUrl,
          'primary_color': _hex(organization.branding.primaryColor),
          'accent_color': _hex(organization.branding.accentColor),
          'contact_phone': organization.branding.contactPhone,
        },
        'features': organization.features.toList(),
      },
  ],
};

User _user(Map<String, dynamic> json) => User(
  id: _field<String>(json, 'id'),
  phone: _field<String>(json, 'phone'),
  name: _optional<String>(json, 'name'),
);

Organization _organization(Map<String, dynamic> json) {
  final branding = _optional<Map<String, dynamic>>(json, 'branding') ?? const <String, dynamic>{};
  return Organization(
    id: _field<String>(json, 'id'),
    name: _field<String>(json, 'name'),
    role: _optional<String>(json, 'role') ?? 'member',
    branding: Branding(
      logoUrl: _optional<String>(branding, 'logo_url'),
      primaryColor: _color(_optional<String>(branding, 'primary_color')),
      accentColor: _color(_optional<String>(branding, 'accent_color')),
      contactPhone: _optional<String>(branding, 'contact_phone'),
    ),
    features: {
      for (final feature in _optional<List<dynamic>>(json, 'features') ?? const <dynamic>[])
        if (feature is String) feature,
    },
  );
}

T _field<T>(Map<String, dynamic> json, String key) => switch (json[key]) {
  final T value => value,
  _ => throw FormatException('Missing or invalid "$key"'),
};

T? _optional<T>(Map<String, dynamic> json, String key) => switch (json[key]) {
  final T value => value,
  _ => null,
};

/// `#RRGGBB` to an opaque colour; anything else counts as unset.
Color? _color(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

String? _hex(Color? color) {
  if (color == null) return null;
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
