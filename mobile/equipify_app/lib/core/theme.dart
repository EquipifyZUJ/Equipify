import 'package:flutter/material.dart';

/// Equipify design language — Professional Blue palette.
/// Matches the web client: blue accent on slate, glassy cards, pill buttons.
abstract final class EqColors {
  static const accent = Color(0xFF2563EB);
  static const accentDeep = Color(0xFF1D4ED8);
  static const accentText = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0F172A);

  static const ok = Color(0xFF10B981);
  static const warn = Color(0xFFF59E0B);
  static const bad = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Light palette
  static const lightBg = Color(0xFFF8FAFC);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0x9E0F172A);

  // Dark palette
  static const darkBg = Color(0xFF0C1222);
  static const darkSurface = Color(0xFF111827);
  static const darkText = Color(0xFFF1F5F9);
  static const darkMuted = Color(0xA3F1F5F9);
}

abstract final class EqRadius {
  static const card = 20.0;
  static const field = 14.0;
  static const pill = 999.0;
}

abstract final class EqShadows {
  static List<BoxShadow> soft(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0x2E18274B),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

class EqTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: EqColors.accent,
      brightness: brightness,
    ).copyWith(
      primary: EqColors.accent,
      onPrimary: EqColors.accentText,
      secondary: isDark ? EqColors.darkSurface : EqColors.ink,
      surface: isDark ? EqColors.darkBg : EqColors.lightBg,
      surfaceContainerHighest:
          isDark ? EqColors.darkSurface : EqColors.lightSurface,
      error: EqColors.bad,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamilyFallback: const ['Cairo', 'Segoe UI'],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EqRadius.card),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        hintStyle: TextStyle(color: colorScheme.outline),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EqRadius.field),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EqRadius.field),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EqRadius.field),
          borderSide: const BorderSide(color: EqColors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EqRadius.field),
          borderSide: const BorderSide(color: EqColors.bad),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EqRadius.field),
          borderSide: const BorderSide(color: EqColors.bad, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: EqColors.accent,
          foregroundColor: EqColors.accentText,
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EqColors.info,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: EqColors.accent.withValues(alpha: 0.22),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        modalBackgroundColor: colorScheme.surfaceContainerHighest,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(EqRadius.card)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EqRadius.pill),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
