part of 'day_detail_screen.dart';

class _SummaryLoadingCard extends StatelessWidget {
  const _SummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LoadingLine(width: 96, height: 18),
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [_LoadingPill(width: 78), _LoadingPill(width: 96)],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLoadingCard extends StatelessWidget {
  const _RouteLoadingCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LoadingLine(width: 96, height: 18),
            SizedBox(height: 8),
            _LoadingLine(width: 120, height: 14),
            SizedBox(height: 12),
            _MapPlaceholderCard(),
            SizedBox(height: 12),
            _LoadingLine(width: 110, height: 14),
          ],
        ),
      ),
    );
  }
}

class _RouteSummaryLoadingCard extends StatelessWidget {
  const _RouteSummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LoadingLine(width: 96, height: 18),
            SizedBox(height: 12),
            _LoadingLine(width: 180, height: 16),
            SizedBox(height: 14),
            _LoadingLine(width: double.infinity, height: 14),
            SizedBox(height: 10),
            _LoadingLine(width: 220, height: 14),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholderCard extends StatelessWidget {
  const _MapPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const SizedBox(
        height: 220,
        width: double.infinity,
        child: Center(
          child: Text(
            '이동 경로를 불러오는 중',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.softBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Text('데이터를 불러오지 못했어요', style: TextStyle(color: AppColors.muted)),
      ),
    );
  }
}
