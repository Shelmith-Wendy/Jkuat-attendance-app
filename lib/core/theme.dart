// lib/core/theme.dart

import 'package:flutter/material.dart';

// ── Brand colours ──────────────────────────────────────────────────────────
const Color primaryGreen = Color(0xFF1B5E20);
const Color lightGreen = Color(0xFF2E7D32);
const Color accentRed = Color(0xFFC62828);
const Color white = Color(0xFFFFFFFF);
const Color darkText = Color(0xFF1A1A1A);
const Color surfaceGrey = Color(0xFFF5F5F5);
const Color cardBorder = Color(0xFFE0E0E0);

// ── App theme ───────────────────────────────────────────────────────────────
final ThemeData jkuatTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryGreen,
    brightness: Brightness.light,
    primary: primaryGreen,
    secondary: lightGreen,
    error: accentRed,
    surface: white,
  ),
  scaffoldBackgroundColor: white,
  fontFamily: 'Roboto',

  // ── AppBar ────────────────────────────────────────────────────────────────
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryGreen,
    foregroundColor: white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: white),
  ),

  // ── ElevatedButton ────────────────────────────────────────────────────────
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightGreen,
      foregroundColor: white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),

  // ── OutlinedButton ────────────────────────────────────────────────────────
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryGreen,
      side: const BorderSide(color: primaryGreen),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  // ── TextButton ────────────────────────────────────────────────────────────
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: primaryGreen),
  ),

  // ── Input fields ──────────────────────────────────────────────────────────
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: surfaceGrey,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: accentRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: accentRed, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
    prefixIconColor: Colors.grey,
    errorStyle: const TextStyle(color: accentRed, fontSize: 12),
  ),

  // ── Card ──────────────────────────────────────────────────────────────────
  cardTheme: CardThemeData(
    elevation: 3,
    color: white,
    shadowColor: Colors.black.withOpacity(0.10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),

  // ── Chip ─────────────────────────────────────────────────────────────────
  chipTheme: ChipThemeData(
    selectedColor: lightGreen,
    backgroundColor: surfaceGrey,
    labelStyle: const TextStyle(fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),

  // ── BottomNavigationBar ───────────────────────────────────────────────────
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: primaryGreen,
    unselectedItemColor: Colors.grey,
    backgroundColor: white,
    elevation: 8,
  ),

  // ── FloatingActionButton ──────────────────────────────────────────────────
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: lightGreen,
    foregroundColor: white,
  ),
);
