import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const mpBg = Color(0xFF0D0D0D);
  static const mpSurface = Color(0xFF1A1A1A);
  static const mpSurface2 = Color(0xFF242424);
  static const mpBorder = Color(0xFF2A2A2A);
  static const mpAccent = Color(0xFF1DB954);
  static const mpAccentDark = Color(0xFF158A3E);
  static const mpText = Color(0xFFFFFFFF);
  static const mpTextSub = Color(0xFF888888);
  static const mpTextMuted = Color(0xFF555555);

  static const background = mpBg;
  static const surface = mpSurface;
  static const surfaceAlt = mpSurface2;
  static const border = mpBorder;
  static const ink = mpText;
  static const muted = mpTextSub;
  static const softBlue = mpAccent;
  static const blueGrey = mpAccent;
  static const paleBlue = Color(0xFF17351F);
  static const pressedBlue = mpAccentDark;
}

class AppThemeDecorations {
  const AppThemeDecorations._();

  static BoxDecoration softCard({Color color = AppColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 22,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration inkCard() {
    return BoxDecoration(
      color: AppColors.mpSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.mpAccent.withValues(alpha: 0.28)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 22,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration quietPanel() {
    return BoxDecoration(
      color: AppColors.paleBlue,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.mpAccent.withValues(alpha: 0.2)),
    );
  }
}
