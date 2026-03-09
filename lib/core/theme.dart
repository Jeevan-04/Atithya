import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AtithyaTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AtithyaColors.obsidian,
      colorScheme: ColorScheme.dark(
        surface: AtithyaColors.obsidian,
        primary: AtithyaColors.imperialGold,
        secondary: AtithyaColors.royalMaroon,
        onSurface: AtithyaColors.pearl,
        onPrimary: AtithyaColors.obsidian,
      ),
      textTheme: TextTheme(
        displayLarge: AtithyaTypography.displayLarge,
        displayMedium: AtithyaTypography.displayMedium,
        bodyLarge: AtithyaTypography.bodyLarge,
        bodyMedium: AtithyaTypography.bodyElegant,
        labelSmall: AtithyaTypography.labelSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AtithyaColors.surfaceElevated,
        contentTextStyle: AtithyaTypography.bodyElegant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: AtithyaColors.imperialGold.withValues(alpha: 0.3)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
