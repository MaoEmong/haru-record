import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFEDF3F7);
  static const surface = Color(0xFFFCFDFE);
  static const surfaceAlt = Color(0xFFF5F9FB);
  static const border = Color(0xFFD3E0E8);
  static const ink = Color(0xFF17232E);
  static const muted = Color(0xFF536676);
  static const softBlue = Color(0xFFAEC7D8);
  static const blueGrey = Color(0xFF3F6F8A);
  static const paleBlue = Color(0xFFE2ECF2);
  static const pressedBlue = Color(0xFFD5E4ED);
}

class AppThemeDecorations {
  const AppThemeDecorations._();

  static BoxDecoration softCard({Color color = AppColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F17232E),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration inkCard() {
    return BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2417232E),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration quietPanel() {
    return BoxDecoration(
      color: AppColors.paleBlue,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    );
  }
}
