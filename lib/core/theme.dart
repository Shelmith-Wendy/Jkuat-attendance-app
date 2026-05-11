import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF1B5E20);
const Color lightGreen = Color(0xFF2E7D32);
const Color accentRed = Color(0xFFC62828);
const Color white = Color(0xFFFFFFFF);
const Color darkText = Color(0xFF1A1A1A);
const Color surfaceGrey = Color(0xFFF5F5F5);

final ThemeData jkuatTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryGreen,
    foregroundColor: white,
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightGreen,
      foregroundColor: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceGrey,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryGreen),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: white,
  ),
);
