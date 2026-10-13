import 'package:material_ui/material_ui.dart';

import 'brand.dart';
import 'tokens.dart';

/// Light theme only for V1. Montserrat for Latin text, with Noto Sans
/// Ethiopic underneath for Amharic.
abstract final class AppTheme {
  static const fontFamily = 'Montserrat';
  static const ethiopicFontFamily = 'NotoSansEthiopic';

  static ThemeData of(Brand brand) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand.primary,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      primary: brand.primary,
      onPrimary: brand.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      error: AppColors.danger,
      // Material 3 tints menus and sheets with the seed; keep them white.
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surface,
      surfaceContainerHighest: AppColors.canvas,
    );
    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: const [ethiopicFontFamily],
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkSparkle.splashFactory,
    );
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control));
    return base.copyWith(
      extensions: [BrandTheme(brand)],
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: controlShape,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.line),
          shape: controlShape,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand.primary,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: _inputBorder(AppColors.line),
        enabledBorder: _inputBorder(AppColors.line),
        focusedBorder: _inputBorder(brand.primary, width: 1.6),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.6),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadii.control))),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(8),
          shadowColor: const WidgetStatePropertyAll(Color(0x33101828)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control))),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
        elevation: 6,
        shadowColor: const Color(0x33101828),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.control),
    borderSide: BorderSide(color: color, width: width),
  );

  static TextTheme _textTheme(TextTheme base) {
    final inked = base.apply(displayColor: AppColors.ink, bodyColor: AppColors.ink);
    return inked.copyWith(
      headlineMedium: inked.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: inked.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: inked.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: inked.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: inked.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      bodyLarge: inked.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: inked.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: inked.bodySmall?.copyWith(fontSize: 12, color: AppColors.textSecondary),
      labelSmall: inked.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    );
  }
}
