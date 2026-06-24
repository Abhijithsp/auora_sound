import 'package:flutter/material.dart';

class AppThemePreset {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color backgroundDark;
  final Color backgroundLight;
  final Color cardDark;
  final Color cardLight;

  const AppThemePreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.backgroundDark,
    required this.backgroundLight,
    required this.cardDark,
    required this.cardLight,
  });
}

class AppThemePresets {
  static const List<AppThemePreset> presets = [
    AppThemePreset(
      name: 'Purple Night',
      primary: Color(0xFF7C4DFF),
      secondary: Color(0xFF651FFF),
      accent: Color(0xFFFF4B7D),
      backgroundDark: Color(0xFF0F0C1B),
      backgroundLight: Color(0xFFF9F9FB),
      cardDark: Color(0xFF1E163B),
      cardLight: Color(0xFFF0F0F5),
    ),
    AppThemePreset(
      name: 'Emerald Green',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF059669),
      accent: Color(0xFF34D399),
      backgroundDark: Color(0xFF070F0D),
      backgroundLight: Color(0xFFF4F9F6),
      cardDark: Color(0xFF0E1F1A),
      cardLight: Color(0xFFEAF5EF),
    ),
    AppThemePreset(
      name: 'Ocean Blue',
      primary: Color(0xFF0EA5E9),
      secondary: Color(0xFF0284C7),
      accent: Color(0xFF38BDF8),
      backgroundDark: Color(0xFF070E1B),
      backgroundLight: Color(0xFFF4F7FB),
      cardDark: Color(0xFF0D1C36),
      cardLight: Color(0xFFE8EFF7),
    ),
    AppThemePreset(
      name: 'Sunset Orange',
      primary: Color(0xFFF97316),
      secondary: Color(0xFFEA580C),
      accent: Color(0xFFFDBA74),
      backgroundDark: Color(0xFF170F0B),
      backgroundLight: Color(0xFFFAF6F4),
      cardDark: Color(0xFF2A1B14),
      cardLight: Color(0xFFF5EAE4),
    ),
    AppThemePreset(
      name: 'Rose Pink',
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFDB2777),
      accent: Color(0xFFF472B6),
      backgroundDark: Color(0xFF170B12),
      backgroundLight: Color(0xFFFAF4F7),
      cardDark: Color(0xFF2B1421),
      cardLight: Color(0xFFF5E4EE),
    ),
    AppThemePreset(
      name: 'Crimson Red',
      primary: Color(0xFFEF4444),
      secondary: Color(0xFFDC2626),
      accent: Color(0xFFF87171),
      backgroundDark: Color(0xFF170B0B),
      backgroundLight: Color(0xFFFAF4F4),
      cardDark: Color(0xFF2B1414),
      cardLight: Color(0xFFF5E4E4),
    ),
    AppThemePreset(
      name: 'Teal Aqua',
      primary: Color(0xFF14B8A6),
      secondary: Color(0xFF0D9488),
      accent: Color(0xFF2DD4BF),
      backgroundDark: Color(0xFF071110),
      backgroundLight: Color(0xFFF4FAF9),
      cardDark: Color(0xFF0E2220),
      cardLight: Color(0xFFE4F5F3),
    ),
    AppThemePreset(
      name: 'Indigo',
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF4F46E5),
      accent: Color(0xFF818CF8),
      backgroundDark: Color(0xFF0A0B1B),
      backgroundLight: Color(0xFFF5F5FA),
      cardDark: Color(0xFF131637),
      cardLight: Color(0xFFEBEBF5),
    ),
    AppThemePreset(
      name: 'Gold',
      primary: Color(0xFFEAB308),
      secondary: Color(0xFFCA8A04),
      accent: Color(0xFFFDE047),
      backgroundDark: Color(0xFF131105),
      backgroundLight: Color(0xFFFAF9F2),
      cardDark: Color(0xFF27220B),
      cardLight: Color(0xFFF5F3E3),
    ),
    AppThemePreset(
      name: 'Monochrome',
      primary: Color(0xFF888888),
      secondary: Color(0xFF555555),
      accent: Color(0xFFCCCCCC),
      backgroundDark: Color(0xFF121212),
      backgroundLight: Color(0xFFF8F8F8),
      cardDark: Color(0xFF222222),
      cardLight: Color(0xFFEEEEEE),
    ),
  ];

  static AppThemePreset getByName(String name) {
    return presets.firstWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
      orElse: () => presets[0],
    );
  }
}
