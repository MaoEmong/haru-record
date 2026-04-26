import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/analysis/daily_summary_service.dart';

void main() {
  test('summarizes visits into stationary minutes and visit count', () {
    final service = DailySummaryService();
    final date = DateTime(2026, 4, 25);

    final summary = service.buildSummary(
      date: date,
      visits: [
        VisitSnapshot(
          durationMinutes: 40,
          distanceFromPreviousMeters: 0,
          isNewPlace: false,
          placeClusterId: 1,
        ),
        VisitSnapshot(
          durationMinutes: 20,
          distanceFromPreviousMeters: 1300,
          isNewPlace: true,
          movingMinutesFromPrevious: 15,
          placeClusterId: 2,
        ),
      ],
    );

    expect(summary.date, date);
    expect(summary.stationaryMinutes, 60);
    expect(summary.visitCount, 2);
    expect(summary.totalDistanceMeters, 1300);
    expect(summary.newPlaceCount, 1);
    expect(summary.movingMinutes, 15);
    expect(summary.longestStayPlaceId, 1);
  });

  test('estimates moving minutes from travel distance when unavailable', () {
    final service = DailySummaryService();

    final summary = service.buildSummary(
      date: DateTime(2026, 4, 25),
      visits: [
        VisitSnapshot(
          durationMinutes: 20,
          distanceFromPreviousMeters: 1600,
          isNewPlace: false,
        ),
      ],
    );

    expect(summary.movingMinutes, greaterThan(0));
  });
}
