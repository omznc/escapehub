import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0.00', 'en_US');
final _day = DateFormat('EEE, d MMM yyyy');
final _shortDay = DateFormat('d MMM');
final _timestamp = DateFormat('d MMM yyyy, HH:mm');

String formatMoney(double value) => '${_money.format(value)} KM';

String formatDay(DateTime date) => _day.format(date);

String formatShortDay(DateTime date) => _shortDay.format(date);

String formatTimestamp(DateTime value) => _timestamp.format(value);

String formatTimeRange(String start, String end) => '$start - $end';

String plural(int count, String noun) => count == 1 ? '1 $noun' : '$count ${noun}s';

String formatPlayers(int min, int max) => min == max ? plural(min, 'player') : '$min-$max players';

String formatPlayerCount(int count) => plural(count, 'player');

String formatPoints(int points) => plural(points, 'point');

String formatMinutes(int minutes) => '$minutes min';

String formatDiscount({required bool isPercentage, required double value}) =>
    isPercentage ? '${NumberFormat('0.##').format(value)}% off' : '${formatMoney(value)} off';
