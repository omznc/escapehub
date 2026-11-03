import 'package:escapehub_core/escapehub_core.dart';

import '../../format.dart';
import '../../widgets/charts.dart';

class ReportData {
  const ReportData({
    required this.title,
    required this.from,
    required this.to,
    required this.columns,
    required this.rows,
    required this.chartTitle,
    required this.chart,
    required this.format,
  });

  final String title;
  final DateTime from;
  final DateTime to;
  final List<String> columns;
  final List<List<String>> rows;
  final String chartTitle;
  final List<ChartPoint> chart;
  final String Function(double value) format;
}

extension ReportTypeLabels on ReportType {
  String get label => switch (this) {
    ReportType.bookings => 'Bookings by period',
    ReportType.revenue => 'Revenue by period',
    ReportType.occupancy => 'Occupancy by room',
    ReportType.topRooms => 'Most popular rooms',
    ReportType.topClients => 'Top clients by bookings',
    ReportType.topClientsBySpending => 'Top clients by spending',
    ReportType.ratings => 'Ratings by room',
    ReportType.loyaltyRedemptions => 'Loyalty redemptions',
  };

  bool get usesTop =>
      const [ReportType.topRooms, ReportType.topClients, ReportType.topClientsBySpending].contains(this);

  bool get usesGroupBy => this == ReportType.bookings || this == ReportType.revenue;

  bool get usesRoom => this != ReportType.loyaltyRedemptions;
}

String _count(double value) => value.toInt().toString();

Future<ReportData> loadReport(ReportsApi api, ReportType type, ReportQuery query) => switch (type) {
  ReportType.bookings => api.bookings(query).then((result) => _bookings(result, query.groupBy)),
  ReportType.revenue => api.revenue(query).then(_revenue),
  ReportType.occupancy => api.occupancy(query).then(_occupancy),
  ReportType.topRooms => api.topRooms(query).then(_topRooms),
  ReportType.topClients => api.topClients(query).then((result) => _topClients(result, bySpending: false)),
  ReportType.topClientsBySpending =>
    api.topClientsBySpending(query).then((result) => _topClients(result, bySpending: true)),
  ReportType.ratings => api.ratings(query).then(_ratings),
  ReportType.loyaltyRedemptions => api.loyaltyRedemptions(query).then(_redemptions),
};

String _period(DateTime date, ReportGroupBy? groupBy) =>
    groupBy == ReportGroupBy.day ? formatDate(date) : formatDate(date).substring(0, 7);

ReportData _bookings(ReportResult<BookingsReportRow> result, ReportGroupBy? groupBy) => ReportData(
  title: result.title,
  from: result.from,
  to: result.to,
  columns: const ['Period', 'Total', 'Pending', 'Confirmed', 'Completed', 'Cancelled', 'No-show', 'Rejected'],
  rows: [
    for (final row in result.rows)
      [
        _period(row.date, groupBy),
        '${row.total}',
        '${row.pending}',
        '${row.confirmed}',
        '${row.completed}',
        '${row.cancelled}',
        '${row.noShow}',
        '${row.rejected}',
      ],
  ],
  chartTitle: 'Bookings in each period',
  chart: [for (final row in result.rows) ChartPoint(_period(row.date, groupBy), row.total.toDouble())],
  format: _count,
);

ReportData _revenue(ReportResult<RevenueReportRow> result) => ReportData(
  title: result.title,
  from: result.from,
  to: result.to,
  columns: const ['Period', 'Bookings', 'Revenue', 'Discounts'],
  rows: [
    for (final row in result.rows)
      [row.period, '${row.bookings}', formatMoney(row.revenue), formatMoney(row.discounts)],
  ],
  chartTitle: 'Revenue in each period',
  chart: [for (final row in result.rows) ChartPoint(row.period, row.revenue)],
  format: formatMoney,
);

ReportData _occupancy(ReportResult<OccupancyReportRow> result) => ReportData(
  title: result.title,
  from: result.from,
  to: result.to,
  columns: const ['Room', 'Time slots', 'Booked slots', 'Occupancy'],
  rows: [
    for (final row in result.rows)
      [row.roomName, '${row.totalSlots}', '${row.bookedSlots}', formatPercent(row.occupancyPercent)],
  ],
  chartTitle: 'Occupancy of each room',
  chart: [for (final row in result.rows) ChartPoint(row.roomName, row.occupancyPercent)],
  format: formatPercent,
);

ReportData _topRooms(ReportResult<TopRoomReportRow> result) => ReportData(
  title: result.title,
  from: result.from,
  to: result.to,
  columns: const ['Room', 'Bookings', 'Revenue', 'Average players'],
  rows: [
    for (final row in result.rows)
      [row.roomName, '${row.bookings}', formatMoney(row.revenue), row.averagePlayers.toStringAsFixed(1)],
  ],
  chartTitle: 'Bookings of each room',
  chart: [for (final row in result.rows) ChartPoint(row.roomName, row.bookings.toDouble())],
  format: _count,
);

ReportData _topClients(ReportResult<TopClientReportRow> result, {required bool bySpending}) => ReportData(
  title: result.title,
  from: result.from,
  to: result.to,
  columns: const ['Client', 'Email', 'Bookings', 'Total spent'],
  rows: [
    for (final row in result.rows) [row.clientName, row.email, '${row.bookings}', formatMoney(row.totalSpent)],
  ],
  chartTitle: bySpending ? 'Money spent by each client' : 'Bookings of each client',
  chart: [
    for (final row in result.rows) ChartPoint(row.clientName, bySpending ? row.totalSpent : row.bookings.toDouble()),
  ],
  format: bySpending ? formatMoney : _count,
);

ReportData _ratings(ReportResult<RatingReportRow> result) => ReportData(
  title: result.title,
  from: result.from,
  to: result.to,
  columns: const ['Room', 'Average', 'Reviews', '5 stars', '4 stars', '3 stars', '2 stars', '1 star'],
  rows: [
    for (final row in result.rows)
      [
        row.roomName,
        row.averageRating.toStringAsFixed(2),
        '${row.reviewCount}',
        '${row.fiveStars}',
        '${row.fourStars}',
        '${row.threeStars}',
        '${row.twoStars}',
        '${row.oneStar}',
      ],
  ],
  chartTitle: 'Average rating of each room',
  chart: [for (final row in result.rows) ChartPoint(row.roomName, row.averageRating)],
  format: (value) => value.toStringAsFixed(2),
);

ReportData _redemptions(ReportResult<RedemptionReportRow> result) => ReportData(
  title: result.title,
  from: result.from,
  to: result.to,
  columns: const ['Reward', 'Redemptions', 'Points spent', 'Used', 'Not used'],
  rows: [
    for (final row in result.rows)
      [row.rewardName, '${row.redemptions}', '${row.pointsSpent}', '${row.used}', '${row.unused}'],
  ],
  chartTitle: 'Redemptions of each reward',
  chart: [for (final row in result.rows) ChartPoint(row.rewardName, row.redemptions.toDouble())],
  format: _count,
);
