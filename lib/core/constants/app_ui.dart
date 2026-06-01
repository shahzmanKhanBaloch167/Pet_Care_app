import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF090040);
  static const Color primaryPurple = Color(0xFF471396);
  static const Color accentPurple = Color(0xFFB13BFF);
  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color white = Colors.white;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}

class AppGradients {
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDark, AppColors.primaryPurple],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentPurple, AppColors.accentYellow],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF090040),
      Color(0xFF471396),
      Color(0xFF2A0845),
    ],
  );
}

class AppStyles {
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;

  static final BorderRadius cardRadius = BorderRadius.circular(borderRadiusMedium);
  static final BorderRadius buttonRadius = BorderRadius.circular(borderRadiusMedium);
  static final BorderRadius inputRadius = BorderRadius.circular(borderRadiusSmall);

  static const EdgeInsets screenPadding = EdgeInsets.all(20.0);
}
