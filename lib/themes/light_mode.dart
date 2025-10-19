import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Colors.grey.shade300,       // unchanged
    onPrimary: Colors.indigo.shade600,
    secondary: Colors.grey.shade100,
    tertiary: Colors.white,
    inversePrimary: Colors.grey.shade600, // darker reverse tone
  ),
  scaffoldBackgroundColor: Colors.grey.shade100,
);
