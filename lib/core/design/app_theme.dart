import 'package:material_ui/material_ui.dart';

/// The app theme. Colours, type and components stay Material defaults until
/// the design direction is set. Only the Ethiopic fallback is decided.
abstract final class AppTheme {
  static const ethiopicFontFamily = 'NotoSansEthiopic';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    brightness: brightness,
    // The default fonts have no Ge'ez glyphs. A bundled fallback keeps
    // Amharic the same on every phone instead of whatever the OS has.
    fontFamilyFallback: const [ethiopicFontFamily],
  );
}
