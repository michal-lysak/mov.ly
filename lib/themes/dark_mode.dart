import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: Colors.grey.shade300,
    secondary: Colors.grey.shade900,
    tertiary: Colors.grey.shade700,
    inversePrimary: Colors.grey.shade600, // darker reverse tone
    surface: Color(0xFF17171B),
  ),
  scaffoldBackgroundColor: Colors.grey.shade900,
);
