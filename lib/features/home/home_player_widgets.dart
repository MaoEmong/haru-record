part of 'home_screen.dart';

class _TrackInfoRow extends StatelessWidget {
  const _TrackInfoRow({
    required this.distanceKm,
    required this.placeCount,
    required this.cheerVisible,
    required this.cheerMessage,
    required this.onCheer,
    required this.isLoading,
  });

  final String distanceKm;
  final int placeCount;
  final bool cheerVisible;
  final String cheerMessage;
  final VoidCallback onCheer;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 하루',
                  style: TextStyle(
                    color: AppColors.mpText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isLoading ? '오늘 기록을 불러오는 중' : '$distanceKm · $placeCount곳 방문',
                  style: const TextStyle(
                    color: AppColors.mpTextSub,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _CheerButton(
            visible: cheerVisible,
            message: cheerMessage,
            onPressed: onCheer,
          ),
        ],
      ),
    );
  }
}

class _CheerButton extends StatelessWidget {
  const _CheerButton({
    required this.visible,
    required this.message,
    required this.onPressed,
  });

  final bool visible;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            top: visible ? -54 : -42,
            right: 0,
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: visible ? 1 : 0,
                child: _CheerBubble(message: message),
              ),
            ),
          ),
          IconButton(
            onPressed: onPressed,
            tooltip: '응원 한마디',
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.mpAccent,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheerBubble extends StatelessWidget {
  const _CheerBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mpBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.mpText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatsChipRow extends StatelessWidget {
  const _StatsChipRow({required this.preview, required this.isLoading});

  final DayActivityPreview preview;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 10, 16, 14),
      child: Row(
        children: [
          _DateChip(month: now.month, day: now.day),
          const _StatChip(
            icon: Icons.directions_walk_rounded,
            value: '--',
            label: '걸음',
          ),
          _StatChip(
            icon: Icons.place_rounded,
            value: isLoading ? '--' : '${preview.visitCount ?? 0}',
            label: '장소',
          ),
          _StatChip(
            icon: Icons.schedule_rounded,
            value: _elapsedLabel(),
            label: '경과',
          ),
        ],
      ),
    );
  }

  String _elapsedLabel() {
    final now = DateTime.now();
    return '${now.hour}h';
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.month, required this.day});

  final int month;
  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.mpSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            '$month월',
            style: const TextStyle(color: AppColors.mpTextSub, fontSize: 10),
          ),
          const SizedBox(width: 5),
          Text(
            '$day',
            style: const TextStyle(
              color: AppColors.mpText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.mpSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.mpTextSub, size: 15),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.mpText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.mpTextSub, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  // ignore: unused_element_parameter
  const _ProgressBar({
    required this.progress,
    required this.timeLabel,
    // ignore: unused_element_parameter
    this.showReturnToCurrent = false,
    // ignore: unused_element_parameter
    this.onReturnToCurrent,
    this.onTap,
  });

  final double progress;
  final String timeLabel;
  final bool showReturnToCurrent;
  final VoidCallback? onReturnToCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visibleProgress = progress.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final knobLeft = constraints.maxWidth * visibleProgress;
              return GestureDetector(
                key: const ValueKey('home-time-scrubber'),
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      height: 12,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.mpSurface2,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: visibleProgress,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.mpText,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (knobLeft - 6).clamp(
                              0,
                              constraints.maxWidth - 12,
                            ),
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.mpText,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeLabel,
                style: const TextStyle(
                  color: AppColors.mpTextSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showReturnToCurrent)
                TextButton(
                  key: const ValueKey('home-return-to-current'),
                  onPressed: onReturnToCurrent,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mpAccent,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '현재로',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                )
              else
                const Text(
                  '23:59',
                  style: TextStyle(
                    color: AppColors.mpTextSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (showReturnToCurrent)
                const Text(
                  '23:59',
                  style: TextStyle(
                    color: AppColors.mpTextSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.preview,
    required this.route,
    required this.onOpenTodayRecords,
  });

  final DayActivityPreview preview;
  final Future<DayRouteSnapshot> route;
  final OpenTodayRecordsCallback? onOpenTodayRecords;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _ControlIcon(Icons.shuffle_rounded, accent: true),
          const _ControlIcon(Icons.skip_previous_rounded),
          _ControlIcon(
            Icons.pause_circle_filled_rounded,
            buttonKey: const ValueKey('home-open-today-records-control'),
            primary: true,
            semanticLabel: '오늘 기록 열기',
            onTap: onOpenTodayRecords == null
                ? null
                : () => onOpenTodayRecords!(preview, route),
          ),
          const _ControlIcon(Icons.skip_next_rounded),
          const _ControlIcon(Icons.repeat_rounded, accent: true),
        ],
      ),
    );
  }
}

class _ControlIcon extends StatelessWidget {
  const _ControlIcon(
    this.icon, {
    this.primary = false,
    this.accent = false,
    this.buttonKey,
    this.semanticLabel,
    this.onTap,
  });

  final IconData icon;
  final bool primary;
  final bool accent;
  final Key? buttonKey;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      semanticLabel: semanticLabel,
      color: primary
          ? AppColors.mpText
          : accent
          ? AppColors.mpAccent
          : AppColors.mpTextSub,
      size: primary ? 58 : 24,
    );
    final size = primary ? 64.0 : 44.0;
    if (onTap == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: iconWidget),
      );
    }

    return SizedBox(
      key: buttonKey,
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.expand(),
        iconSize: primary ? 58 : 24,
        tooltip: semanticLabel,
        onPressed: onTap,
        icon: iconWidget,
      ),
    );
  }
}
