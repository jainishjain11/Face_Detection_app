import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color accent = Color(0xFF2196F3);
  static const Color accentDark = Color(0xFF1565C0);

  // Face detection
  static const Color faceBox = Color(0xFF4CAF50);
  static const Color faceBoxFill = Color(0x334CAF50);

  // Dark theme
  static const Color dark = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF252525);
  static const Color darkDivider = Color(0xFF2A2A2A);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF6B6B6B);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64B5F6);
}

class AppStrings {
  static const String appName = 'Face Detection Pro';
  static const String tagLine = 'Real-time AI Face Detection';

  // Auth
  static const String login = 'Login';
  static const String register = 'Create Account';
  static const String email = 'Email Address';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String otpVerification = 'OTP Verification';
  static const String enterOtp = 'Enter 6-digit OTP';
  static const String sendOtp = 'Send OTP';
  static const String verifyOtp = 'Verify OTP';
  static const String resendOtp = 'Resend OTP';
  static const String logout = 'Logout';
  static const String deleteAccount = 'Delete Account';

  // Camera
  static const String cameraScreen = 'Face Detection';
  static const String facesDetected = 'faces detected';
  static const String fps = 'FPS';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Check your connection.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String weakPassword =
      'Password must be at least 8 characters with a number and special character.';
  static const String passwordMismatch = 'Passwords do not match.';
  static const String emptyField = 'This field cannot be empty.';
  static const String otpExpired = 'OTP has expired. Please request a new one.';
  static const String invalidOtp = 'Invalid OTP. Please try again.';
  static const String maxOtpAttempts =
      'Too many attempts. Please request a new OTP.';
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.dark,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkDivider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.dark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkDivider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCard,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
  );
}

class AppConstants {
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;
  static const int maxOtpAttempts = 3;
  static const int splashDurationSeconds = 3;
  static const double minFaceSize = 0.15;
  static const int targetFps = 30;
  static const double faceBoxStrokeWidth = 2.5;
}
