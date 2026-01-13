import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80,
              color: AppColors.primary,
            ),
            SizedBox(height: 20),
            Text(
              'Settings Screen',
              style: AppTextStyles.heading,
            ),
            SizedBox(height: 10),
            Text(
              'Manage your app settings',
              style: AppTextStyles.subheading,
            ),
          ],
        ),
      ),
    );
  }
}
