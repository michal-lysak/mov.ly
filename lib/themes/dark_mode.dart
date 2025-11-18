import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: Colors.grey.shade300,       // unchanged
    onPrimary: Colors.indigo.shade600,
    secondary: Colors.grey.shade100,
    tertiary: Colors.white,
    inversePrimary: Colors.grey.shade600, // darker reverse tone
    surface: Color(0xFF17171B),
  ),
  scaffoldBackgroundColor: Colors.grey.shade900,
);
