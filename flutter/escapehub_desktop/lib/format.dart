import 'package:escapehub_core/escapehub_core.dart';

String _two(int value) => value.toString().padLeft(2, '0');

String formatMoney(double value) => '${value.toStringAsFixed(2)} KM';

String formatPercent(double value) => '${value.toStringAsFixed(1)} %';

String formatNumber(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

String formatDiscount(double value, {required bool isPercentage}) =>
    isPercentage ? '${formatNumber(value)} %' : formatMoney(value);

String formatTimestamp(DateTime value) => '${formatDate(value)} ${_two(value.hour)}:${_two(value.minute)}';

String formatTime(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

String formatDateRange(DateTime from, DateTime to) => '${formatDate(from)} to ${formatDate(to)}';

String formatRating(double value) => value == 0 ? 'No ratings' : '${value.toStringAsFixed(1)} / 5';

String roleLabel(String role) => switch (role) {
  Roles.administrator => 'Administrator',
  Roles.roomManager => 'Room manager',
  _ => 'Client',
};

String bookingStatusLabel(BookingStatus status) => switch (status) {
  BookingStatus.pending => 'Pending',
  BookingStatus.confirmed => 'Confirmed',
  BookingStatus.completed => 'Completed',
  BookingStatus.cancelled => 'Cancelled',
  BookingStatus.noShow => 'No-show',
  BookingStatus.rejected => 'Rejected',
};

String weekdayLabel(DateTime date) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime addDays(DateTime date, int days) => DateTime(date.year, date.month, date.day + days);

DateTime startOfWeek(DateTime date) => addDays(date, 1 - date.weekday);

String? optionalText(String value) => value.trim().isEmpty ? null : value.trim();
