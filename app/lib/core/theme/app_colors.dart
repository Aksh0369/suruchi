import 'package:flutter/material.dart';

/// Fixed per-category accent colors, used everywhere a category shows up
/// (cards, chips, notification icons) so the three stay visually distinct.
class AppColors {
  AppColors._();

  static const business = Color(0xFF3D5AFE);
  static const businessSoft = Color(0xFFE7EAFE);
  static const businessSoftDark = Color(0xFF20264A);

  static const self = Color(0xFF7C4DFF);
  static const selfAccent = Color(0xFF26A69A);
  static const selfSoft = Color(0xFFEEE7FC);
  static const selfSoftDark = Color(0xFF2A2148);

  static const seva = Color(0xFFFF9933);
  static const sevaSoft = Color(0xFFFFF1DB);
  static const sevaSoftDark = Color(0xFF4A3419);

  // Brand neutral palette — drives the overall theme (backgrounds, cards,
  // primary accent). Independent of the category colors above.
  static const brandPrimary = Color(0xFF287094);
  static const brandLightSurface = Color(0xFFD4D4CE);
  static const brandLightBackground = Color(0xFFF6F6F6);
  static const brandDarkBackground = Color(0xFF023246);
}
