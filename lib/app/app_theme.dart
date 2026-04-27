import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFE9F0F5);
  static const surface = Color(0xFFF9FBFD);
  static const surfaceAlt = Color(0xFFF4F7F8);
  static const border = Color(0xFFD9E2EA);
  static const ink = Color(0xFF17222D);
  static const muted = Color(0xFF516171);
  static const softBlue = Color(0xFFB8C9D8);
}

class AppThemeDecorations {
  const AppThemeDecorations._();

  static BoxDecoration softCard({Color color = AppColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141F3142),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration inkCard() {
    return BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24152234),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    );
  }
}
