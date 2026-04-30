part of 'day_detail_screen.dart';

class _RoutePreviewCard extends StatelessWidget {
  const _RoutePreviewCard({
    required this.route,
    required this.dateKey,
    required this.date,
    required this.database,
    required this.settingsRepository,
    required this.initialPreview,
    required this.initialRoute,
  });

  final DayRouteSnapshot route;
  final String dateKey;
  final DateTime date;
  final AppDatabase database;
  final SettingsRepository? settingsRepository;
  final DayActivityPreview? initialPreview;
  final Future<DayRouteSnapshot> initialRoute;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이동 경로',
              style: TextStyle(
                fontSize: responsiveTitleFontSize(context, 18),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '지도 핀 ${_routeMarkerCount(route)}개',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (route.points.length < 2)
              const Text(
                '경로를 그릴 만큼 위치 기록이 아직 부족해요.',
                style: TextStyle(color: AppColors.muted),
              )
            else ...[
              _DayRouteMap(route: route),
              const SizedBox(height: 12),
              Text(
                '${route.points.first.timeLabel} -> ${route.points.last.timeLabel}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('day-detail-open-flow'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => DayFlowPlaybackScreen(
                          database: database,
                          date: date,
                          settingsRepository: settingsRepository,
                          initialPreview: initialPreview,
                          initialRoute: initialRoute,
                        ),
                      ),
                    );
                  },
                  child: const Text('그날의 흐름 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

int _routeMarkerCount(DayRouteSnapshot route) {
  if (route.points.isEmpty) return route.visits.length;
  return (route.points.length == 1 ? 1 : 2) + route.visits.length;
}
