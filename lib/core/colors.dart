import 'package:flutter/material.dart';

class AtithyaColors {
  // === Core Canvas ===
  static const Color obsidian       = Color(0xFF080A0E);       // Absolute dark
  static const Color deepMidnight   = Color(0xFF0D1117);       // Slightly lighter
  static const Color darkSurface    = Color(0xFF12161E);       // Card surfaces
  static const Color surfaceElevated= Color(0xFF1A1E28);       // Elevated glass

  // === Gold System ===
  static const Color imperialGold   = Color(0xFFD4AF6A);       // Headline gold
  static const Color burnishedGold  = Color(0xFFC09040);       // Button accent
  static const Color subtleGold     = Color(0xFF8F6E30);       // Muted accents
  static const Color shimmerGold    = Color(0xFFF5DFA0);       // Shimmer highlight

  // === Royal Maroon ===
  static const Color royalMaroon    = Color(0xFF6B1A2C);       // Rich maroon
  static const Color deepMaroon     = Color(0xFF4A0F1F);       // Darker maroon
  static const Color roseGlow       = Color(0xFF9B3050);       // Hover / active

  // === Cream / Ivory System ===
  static const Color pearl          = Color(0xFFF7F2E8);       // Primary text
  static const Color cream          = Color(0xFFEDE5D0);       // Secondary text
  static const Color parchment      = Color(0xFFD4C9A8);       // Tertiary / captions
  static const Color ashWhite       = Color(0xFF8A8078);       // Disabled

  // === Semantic ===
  static const Color success        = Color(0xFF2E7D5A);
  static const Color errorRed       = Color(0xFF8B1A1A);

  // === Legacy aliases (for backward compat) ===
  static const Color pureBlack      = obsidian;
  static const Color pureIvory      = pearl;
  static const Color antiqueGold    = imperialGold;
  static const Color mutedGold      = subtleGold;
  static const Color etherealGrey   = darkSurface;
  static const Color glassDark      = Color(0x88080A0E);
  static const Color glassLight     = Color(0x22F7F2E8);

  // === Gradients ===
  static const LinearGradient goldGradient = LinearGradient(
    colors: [shimmerGold, imperialGold, burnishedGold],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient maroonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [royalMaroon, deepMaroon],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00080A0E), Color(0xD0080A0E), Color(0xFF080A0E)],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00080A0E), Color(0xFF080A0E)],
    stops: [0.3, 1.0],
  );
}
