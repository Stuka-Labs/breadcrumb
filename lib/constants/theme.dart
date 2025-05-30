import 'package:flutter/material.dart';

// Apple-inspired color palette
const Color kBackgroundColor = Colors.white;
const Color kPastelOrange = Color(0xFFFFB870); // Soft pastel orange
const Color kTextColor = Color(0xFF222222);
const Color kCardColor = Color(0xFFF8F8F8);
const Color kShadowColor = Color(0x1A000000);

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: kBackgroundColor,
  primaryColor: kPastelOrange,
  colorScheme: ColorScheme.light(
    primary: kPastelOrange,
    secondary: kPastelOrange,
    background: kBackgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: kTextColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kBackgroundColor,
    elevation: 0,
    iconTheme: IconThemeData(color: kPastelOrange),
    titleTextStyle: TextStyle(
      color: kTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 22,
      letterSpacing: -0.5,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(
      color: kTextColor,
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
    bodyLarge: TextStyle(
      color: kTextColor,
      fontSize: 16,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
  ),
  cardColor: kCardColor,
  cardTheme: CardTheme(
    color: kCardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    shadowColor: kShadowColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPastelOrange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      elevation: 2,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPastelOrange),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPastelOrange, width: 2),
    ),
    labelStyle: TextStyle(color: kPastelOrange),
  ),
);

// Gradient utility
LinearGradient appHeaderGradient = const LinearGradient(
  colors: [Color(0xFFFFE0B2), Color(0xFFFFB870)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
); 