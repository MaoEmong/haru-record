import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFECEFD8);
  static const surface = Color(0xFFFEF9EC);
  static const surfaceAlt = Color(0xFFECEFD8);
  static const border = Color(0xFF849561);
  static const ink = Color(0xFF202B08);
  static const muted = Color(0xFF45664F);
  static const softBlue = Color(0xFFADBF8D);
  static const blueGrey = Color(0xFF417939);
  static const paleBlue = Color(0xFFD6E1B7);
  static const pressedBlue = Color(0xFFC9D7A4);
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
