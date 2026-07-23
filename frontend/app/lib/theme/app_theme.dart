import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema visual do Achapramim, derivado do Brand System em
/// frontend/mockups/achapramim_brand_system/DESIGN.md (dark) e
/// frontend/mockups/modern_industrial_light/DESIGN.md (light).
///
/// O tema light é o padrão do app; o dark é oferecido como alternativa.
class AppTheme {
  AppTheme._();

  static const _radiusSm = 4.0;
  static const _radiusMd = 8.0;
  static const _radiusLg = 12.0;

  static ThemeData light() => _build(_lightScheme);

  static ThemeData dark() => _build(_darkScheme);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    surface: Color(0xFFF7F9FB),
    onSurface: Color(0xFF191C1E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2F4F6),
    surfaceContainer: Color(0xFFECEEF0),
    surfaceContainerHigh: Color(0xFFE6E8EA),
    surfaceContainerHighest: Color(0xFFE0E3E5),
    surfaceDim: Color(0xFFD8DADC),
    surfaceBright: Color(0xFFF7F9FB),
    onSurfaceVariant: Color(0xFF4F4632),
    inverseSurface: Color(0xFF2D3133),
    onInverseSurface: Color(0xFFEFF1F3),
    outline: Color(0xFF827660),
    outlineVariant: Color(0xFFD4C5AB),
    primary: Color(0xFF785900),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFC107),
    onPrimaryContainer: Color(0xFF6D5100),
    inversePrimary: Color(0xFFFABD00),
    secondary: Color(0xFF545F73),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD5E0F8),
    onSecondaryContainer: Color(0xFF586377),
    tertiary: Color(0xFF595F66),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC5CBD3),
    onTertiaryContainer: Color(0xFF4F565C),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    surface: Color(0xFF031427),
    onSurface: Color(0xFFD3E4FE),
    surfaceContainerLowest: Color(0xFF000F21),
    surfaceContainerLow: Color(0xFF0B1C30),
    surfaceContainer: Color(0xFF102034),
    surfaceContainerHigh: Color(0xFF1B2B3F),
    surfaceContainerHighest: Color(0xFF26364A),
    surfaceDim: Color(0xFF031427),
    surfaceBright: Color(0xFF2A3A4F),
    onSurfaceVariant: Color(0xFFD4C5AB),
    inverseSurface: Color(0xFFD3E4FE),
    onInverseSurface: Color(0xFF213145),
    outline: Color(0xFF9C8F78),
    outlineVariant: Color(0xFF4F4632),
    primary: Color(0xFFFFE4AF),
    onPrimary: Color(0xFF3F2E00),
    primaryContainer: Color(0xFFFFC107),
    onPrimaryContainer: Color(0xFF6D5100),
    inversePrimary: Color(0xFF785900),
    secondary: Color(0xFFBEC6E0),
    onSecondary: Color(0xFF283044),
    secondaryContainer: Color(0xFF3F465C),
    onSecondaryContainer: Color(0xFFADB4CE),
    tertiary: Color(0xFFDCE7FF),
    onTertiary: Color(0xFF263143),
    tertiaryContainer: Color(0xFFC0CBE3),
    onTertiaryContainer: Color(0xFF4B566A),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMd),
          borderSide: BorderSide(color: scheme.primaryContainer, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMd),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
