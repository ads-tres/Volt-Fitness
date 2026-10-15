import 'dart:ui' show Color;

import '../network/json.dart';
import '../tenant/organization.dart';
import 'profile.dart';

/// Reads the `{user, organizations}` object that both OTP verify and `/me`
/// return. Throws a [FormatException] when required fields are missing.
Profile profileFromJson(Map<String, dynamic> json) => Profile(
  user: _user(json.field<Map<String, dynamic>>('user')),
  organizations: [
    for (final organization in json.field<List<dynamic>>('organizations'))
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
  id: json.field<String>('id'),
  phone: json.field<String>('phone'),
  name: json.optional<String>('name'),
);

Organization _organization(Map<String, dynamic> json) {
  final branding = json.optional<Map<String, dynamic>>('branding') ?? const <String, dynamic>{};
  return Organization(
    id: json.field<String>('id'),
    name: json.field<String>('name'),
    role: json.optional<String>('role') ?? 'member',
    branding: Branding(
      logoUrl: branding.optional<String>('logo_url'),
      primaryColor: _color(branding.optional<String>('primary_color')),
      accentColor: _color(branding.optional<String>('accent_color')),
      contactPhone: branding.optional<String>('contact_phone'),
    ),
    features: {
      for (final feature in json.optional<List<dynamic>>('features') ?? const <dynamic>[])
        if (feature is String) feature,
    },
  );
}

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
