import 'package:material_ui/material_ui.dart';

/// Warm neutrals shared by every gym. A gym only changes the brand colour.
abstract final class AppColors {
  /// Text, buttons and the navigation bar.
  static const ink = Color(0xFF1F1E1D);

  /// The navigation bar the pages curve down into.
  static const night = Color(0xFF262524);
  static const textSecondary = Color(0xFF7C766F);
  static const textTertiary = Color(0xFFA9A39C);
  static const line = Color(0xFFEBE6E0);

  /// The page: warm off-white at the top into cream.
  static const canvasTop = Color(0xFFFBFAF7);
  static const canvas = Color(0xFFF2EEE8);
  static const surface = Color(0xFFFFFFFF);
  static const danger = Color(0xFFD92D20);
}

abstract final class AppRadii {
  static const card = 24.0;
  static const control = 16.0;
  static const tile = 14.0;
}

abstract final class AppShadows {
  static const card = [BoxShadow(color: Color(0x101E1A16), blurRadius: 24, offset: Offset(0, 8))];
  static const raised = [BoxShadow(color: Color(0x241E1A16), blurRadius: 20, offset: Offset(0, 8))];
}
