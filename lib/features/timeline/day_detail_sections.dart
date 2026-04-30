part of 'day_detail_screen.dart';

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.preview});

  final AsyncValue<DayActivityPreview> preview;

  @override
  Widget build(BuildContext context) {
    return preview.when(
      loading: () => const _SummaryLoadingCard(),
      error: (_, _) => const _SectionErrorCard(),
      data: (preview) => _SummaryCard(preview: preview),
    );
  }
}

class _RoutePreviewSection extends StatelessWidget {
  const _RoutePreviewSection({
    required this.route,
    required this.preview,
    required this.dateKey,
    required this.date,
    required this.database,
    required this.settingsRepository,
    required this.initialPreview,
    required this.initialRoute,
  });

  final AsyncValue<DayRouteSnapshot> route;
  final AsyncValue<DayActivityPreview> preview;
  final String dateKey;
  final DateTime date;
  final AppDatabase database;
  final SettingsRepository? settingsRepository;
  final DayActivityPreview? initialPreview;
  final Future<DayRouteSnapshot>? initialRoute;

  @override
  Widget build(BuildContext context) {
    return route.when(
      loading: () => const _RouteLoadingCard(),
      error: (_, _) => const _SectionErrorCard(),
      data: (route) => _RoutePreviewCard(
        route: route,
        dateKey: dateKey,
        date: date,
        database: database,
        settingsRepository: settingsRepository,
        initialPreview: initialPreview ?? preview.value,
        initialRoute: initialRoute ?? Future.value(route),
      ),
    );
  }
}

class _RouteSummarySection extends StatelessWidget {
  const _RouteSummarySection({
    required this.preview,
    required this.onSavePlace,
  });

  final AsyncValue<DayActivityPreview> preview;
  final ValueChanged<DayTimelineItem> onSavePlace;

  @override
  Widget build(BuildContext context) {
    return preview.when(
      loading: () => const _RouteSummaryLoadingCard(),
      error: (_, _) => const _SectionErrorCard(),
      data: (preview) =>
          _RouteSummaryCard(items: preview.timeline, onSavePlace: onSavePlace),
    );
  }
}
