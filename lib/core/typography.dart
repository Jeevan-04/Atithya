import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AtithyaTypography {
  // === Cinzel: Monumental Roman Inscriptions ===
  static TextStyle get heroTitle => GoogleFonts.cinzel(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    letterSpacing: 4.0,
    height: 1.0,
    color: AtithyaColors.pearl,
  );

  static TextStyle get displayLarge => GoogleFonts.cinzel(
    fontSize: 38,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
    height: 1.15,
    color: AtithyaColors.pearl,
  );

  static TextStyle get displayMedium => GoogleFonts.cinzel(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    height: 1.2,
    color: AtithyaColors.pearl,
  );

  static TextStyle get displaySmall => GoogleFonts.cinzel(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    height: 1.3,
    color: AtithyaColors.pearl,
  );

  static TextStyle get goldTitle => GoogleFonts.cinzel(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
    color: AtithyaColors.imperialGold,
  );

  // === EB Garamond: Editorial Story Text ===
  static TextStyle get bodyLarge => GoogleFonts.ebGaramond(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.85,
    letterSpacing: 0.3,
    color: AtithyaColors.cream,
  );

  static TextStyle get bodyElegant => GoogleFonts.ebGaramond(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.75,
    letterSpacing: 0.2,
    color: AtithyaColors.parchment,
  );

  static TextStyle get displayItalic => GoogleFonts.ebGaramond(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    height: 1.2,
    color: AtithyaColors.imperialGold,
  );

  // === Inter: Precision Data Labels ===
  static TextStyle get labelMicro => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 4.5,
    color: AtithyaColors.ashWhite,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 3.0,
    color: AtithyaColors.imperialGold,
  );

  static TextStyle get labelGold => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.5,
    color: AtithyaColors.shimmerGold,
  );

  static TextStyle get price => GoogleFonts.cinzel(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AtithyaColors.imperialGold,
    letterSpacing: 1.0,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    color: AtithyaColors.ashWhite,
  );

  // === Convenience aliases ===
  /// Body text for UI components (Inter, 13px)
  static TextStyle get bodyText => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
    color: AtithyaColors.parchment,
  );

  /// Card / section headings (Cinzel, 13px semibold)
  static TextStyle get cardTitle => GoogleFonts.cinzel(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AtithyaColors.pearl,
  );
}
