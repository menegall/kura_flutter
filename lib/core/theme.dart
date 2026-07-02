import 'package:flutter/material.dart';
class AppColors {
  static const Color terraCotta = Color(0xFFC26D50);
  static const Color beige = Color(0xFFE6DFD3);
  static const Color darkGreen = Color(0xFF4A5840);
  static const Color offWhite = Color(0xFFFDFBF7);
  static const Color blueGrey = Color(0xFF78909C);
}
final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.offWhite,
  primaryColor: AppColors.darkGreen,
  colorScheme: const ColorScheme.light(
    primary: AppColors.darkGreen,
    secondary: AppColors.terraCotta,
    surface: AppColors.beige,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.darkGreen,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.terraCotta,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.blueGrey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.blueGrey, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkGreen, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.darkGreen),
  ),
);