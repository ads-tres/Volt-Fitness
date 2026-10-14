import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../tenant/organization.dart';
import '../tenant/selected_organization.dart';
import 'tokens.dart';

/// The colours and logo the app is drawn with: Volt's before sign-in, the
/// gym's after.
final class Brand {
  const Brand({required this.name, required this.primary, this.accent, this.logoUrl, this.isPlatform = false});

  factory Brand.of(Organization organization) => Brand(
    name: organization.name,
    primary: organization.branding.primaryColor ?? volt.primary,
    accent: organization.branding.accentColor,
    logoUrl: organization.branding.logoUrl,
  );

  static const volt = Brand(name: 'Volt Fitness', primary: Color(0xFFC3203A), isPlatform: true);

  final String name;
  final Color primary;
  final Color? accent;
  final String? logoUrl;

  /// Volt itself, whose logo ships with the app.
  final bool isPlatform;

  /// Text and icons on [primary]: white unless the gym picked a light colour.
  Color get onPrimary => primary.computeLuminance() > 0.45 ? AppColors.ink : Colors.white;

  /// The brand on the dark navigation bar, lightened when the gym's colour
  /// is too dark to stand out there.
  Color get onNight {
    var color = primary;
    for (var i = 0; i < 4 && color.computeLuminance() < 0.18; i++) {
      color = Color.lerp(color, Colors.white, 0.25)!;
    }
    return color;
  }

  /// The two ends of the gradient on icon tiles and the QR button.
  (Color, Color) get gradient => (Color.lerp(primary, Colors.white, 0.22)!, primary);
}

final brandProvider = Provider<Brand>((ref) {
  final organization = ref.watch(selectedOrganizationProvider);
  return organization == null ? Brand.volt : Brand.of(organization);
});

/// The brand inside the widget tree, read with `context.brand`.
final class BrandTheme extends ThemeExtension<BrandTheme> {
  const BrandTheme(this.brand);

  final Brand brand;

  @override
  BrandTheme copyWith({Brand? brand}) => BrandTheme(brand ?? this.brand);

  @override
  BrandTheme lerp(BrandTheme? other, double t) => t < 0.5 || other == null ? this : other;
}

extension BrandContext on BuildContext {
  Brand get brand => Theme.of(this).extension<BrandTheme>()?.brand ?? Brand.volt;
}
