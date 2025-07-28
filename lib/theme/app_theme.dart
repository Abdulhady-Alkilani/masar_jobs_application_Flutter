import 'package:flutter/material.dart';

class AppTheme {
  static const _lightColorScheme = ColorScheme.light(
    primary: Color(0xFF005A9C),
    secondary: Color(0xFF00A9B7),
    background: Color(0xFFF5F5F5),
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Color(0xFF121212),
    onSurface: Color(0xFF121212),
    error: Colors.redAccent,
    onError: Colors.white,
  );

  static const _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF3792E2),
    secondary: Color(0xFF00A9B7),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onBackground: Colors.white,
    onSurface: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
  );

  static final _textTheme = const TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.normal),
  ).apply(fontFamily: 'Cairo');

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _lightColorScheme.primary,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: _lightColorScheme.background,
    appBarTheme: AppBarTheme(
      color: _lightColorScheme.primary,
      elevation: 4,
      iconTheme: IconThemeData(color: _lightColorScheme.onPrimary),
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: _lightColorScheme.onPrimary),
    ),
    textTheme: _textTheme,
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
      buttonColor: _lightColorScheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _lightColorScheme.onPrimary,
        backgroundColor: _lightColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(width: 2, color: _lightColorScheme.primary),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _lightColorScheme.primary.withOpacity(0.7), // Glassy blue effect
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkColorScheme.primary,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: _darkColorScheme.background,
    appBarTheme: AppBarTheme(
      color: _darkColorScheme.surface,
      elevation: 4,
      iconTheme: IconThemeData(color: _darkColorScheme.onSurface),
      titleTextStyle: _textTheme.titleLarge?.copyWith(color: _darkColorScheme.onSurface),
    ),
    textTheme: _textTheme,
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
      buttonColor: _darkColorScheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _darkColorScheme.onPrimary,
        backgroundColor: _darkColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1, color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(width: 2, color: _darkColorScheme.primary),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _darkColorScheme.primary.withOpacity(0.7), // Glassy blue effect
    ),
  );
}
