import 'package:flutter/widgets.dart';

double responsiveTitleFontSize(
  BuildContext context,
  double baseSize, {
  double baseWidth = 390,
  double minScale = 0.94,
  double maxScale = 1.12,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final scale = (width / baseWidth).clamp(minScale, maxScale);
  return baseSize * scale;
}
