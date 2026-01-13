import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF162334);
  static const Color white = Colors.white;
  static const Color grey = Colors.grey;
  static const Color lightGrey = Color(0xFFE0E0E0);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    color: AppColors.grey,
  );

  static const TextStyle navSelected = TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle navUnselected = TextStyle(
    color: AppColors.grey,
  );
}

class AppIconThemes {
  static const IconThemeData selectedIcon = IconThemeData(
    color: AppColors.primary,
    size: 28,
  );

  static const IconThemeData unselectedIcon = IconThemeData(
    color: AppColors.grey,
    size: 24,
  );
}
