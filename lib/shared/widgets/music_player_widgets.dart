import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class MpPageHeader extends StatelessWidget {
  const MpPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.mpText,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.mpTextSub,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class MpSectionHeader extends StatelessWidget {
  const MpSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.mpText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mpAccent,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class MpStatStrip extends StatelessWidget {
  const MpStatStrip({super.key, required this.items});

  final List<MpStatItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.mpSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mpBorder),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(child: _StatCell(item: items[index])),
            if (index != items.length - 1)
              Container(width: 1, height: 44, color: AppColors.mpBorder),
          ],
        ],
      ),
    );
  }
}

class MpStatItem {
  const MpStatItem(this.value, this.label);

  final String value;
  final String label;
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.item});

  final MpStatItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.mpText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(
              color: AppColors.mpTextMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({
    super.key,
    required this.values,
    this.height = 46,
    this.playedFraction = 1,
    this.playedColor = AppColors.mpText,
    this.idleColor = AppColors.mpSurface2,
    this.animate = false,
  });

  final List<double> values;
  final double height;
  final double playedFraction;
  final Color playedColor;
  final Color idleColor;
  final bool animate;

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values.isEmpty
        ? defaultWaveformValues()
        : widget.values;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WaveformPainter(
              values: values,
              playedFraction: widget.playedFraction,
              playedColor: widget.playedColor,
              idleColor: widget.idleColor,
              animatedValue: widget.animate ? _controller.value : 0,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.values,
    required this.playedFraction,
    required this.playedColor,
    required this.idleColor,
    required this.animatedValue,
  });

  final List<double> values;
  final double playedFraction;
  final Color playedColor;
  final Color idleColor;
  final double animatedValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    final count = values.length;
    final gap = count > 36 ? 3.0 : 4.0;
    final barWidth = math.max(2.5, (size.width - gap * (count - 1)) / count);
    final playedPaint = Paint()..color = playedColor;
    final idlePaint = Paint()..color = idleColor;
    final radius = Radius.circular(barWidth);

    for (var index = 0; index < count; index++) {
      final normalized = values[index].clamp(0.08, 1.0);
      final pulse = animatedValue == 0
          ? 1.0
          : (0.82 +
                math.sin((animatedValue * math.pi * 2) + index * 0.6) * 0.16);
      final barHeight = (size.height * normalized * pulse).clamp(
        3.0,
        size.height,
      );
      final left = index * (barWidth + gap);
      final top = (size.height - barHeight) / 2;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        index / count <= playedFraction ? playedPaint : idlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.playedFraction != playedFraction ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.idleColor != idleColor ||
        oldDelegate.animatedValue != animatedValue;
  }
}

class AlbumArtCard extends StatelessWidget {
  const AlbumArtCard({
    super.key,
    required this.child,
    this.height,
    this.borderRadius = 18,
    this.accent = AppColors.mpAccent,
  });

  final Widget child;
  final double? height;
  final double borderRadius;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.9),
              const Color(0xFF0A1C0D),
              AppColors.mpSurface,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

List<double> defaultWaveformValues([int count = 44]) {
  return [
    for (var index = 0; index < count; index++)
      0.2 + (math.sin(index * 0.72).abs() * 0.62) + (index % 5) * 0.035,
  ].map((value) => value.clamp(0.12, 1.0)).toList(growable: false);
}
