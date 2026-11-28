import 'dart:ui' show Color;

/// A gym the member belongs to. The API calls it an organization.
final class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.role,
    this.branding = const Branding(),
    this.features = const {},
    this.paused = false,
  });

  final String id;
  final String name;

  /// `member` in this app. Kept as text so a new role can't break parsing.
  final String role;
  final Branding branding;

  /// Modules the gym has switched on, such as `classes` or `online_payments`.
  /// Hiding a feature is only UX; the API still authorizes every call.
  final Set<String> features;

  /// The platform paused the gym: its routes answer `403 GYM_PAUSED` until
  /// it is back (the API's ADR 0043).
  final bool paused;
}

/// What a gym may customise: its logo, colours and contact. Nothing else is
/// server-driven.
final class Branding {
  const Branding({this.logoUrl, this.primaryColor, this.accentColor, this.contactPhone});

  final String? logoUrl;
  final Color? primaryColor;
  final Color? accentColor;
  final String? contactPhone;
}
