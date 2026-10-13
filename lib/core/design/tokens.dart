import 'package:material_ui/material_ui.dart';

/// Neutrals shared by every gym. A gym only changes the brand colour.
abstract final class AppColors {
  /// Text, the dark action cards and the primary button.
  static const ink = Color(0xFF15171C);
  static const textSecondary = Color(0xFF667085);
  static const textTertiary = Color(0xFF98A2B3);
  static const line = Color(0xFFE7EAF0);
  static const canvas = Color(0xFFF4F6F9);
  static const surface = Color(0xFFFFFFFF);
  static const danger = Color(0xFFD92D20);
}

abstract final class AppRadii {
  static const card = 24.0;
  static const control = 16.0;
  static const tile = 14.0;
}

abstract final class AppShadows {
  static const card = [BoxShadow(color: Color(0x0F101828), blurRadius: 24, offset: Offset(0, 8))];
  static const raised = [BoxShadow(color: Color(0x1F101828), blurRadius: 20, offset: Offset(0, 8))];
}
