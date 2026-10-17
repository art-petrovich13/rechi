import 'package:flutter/material.dart';

import 'package:mini_app/core/constants.dart';
import 'package:mini_app/theme/app_theme.dart';
import 'package:mini_app/widgets/app_logo.dart';

/// Экран загрузки и проверки аккаунта.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppLogo(size: 96),
                SizedBox(height: 26),
                Text(
                  appName,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  appTagline,
                  style: TextStyle(fontSize: 17, color: AppColors.muted),
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(height: 16),
                Text(
                  'Проверяем аккаунт…',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
