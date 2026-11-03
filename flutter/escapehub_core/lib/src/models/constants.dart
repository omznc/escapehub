abstract final class Roles {
  static const administrator = 'Administrator';
  static const roomManager = 'RoomManager';
  static const client = 'Client';

  static const all = [administrator, roomManager, client];
  static const staff = [administrator, roomManager];
}

enum BookingStatus {
  pending(1),
  confirmed(2),
  completed(3),
  cancelled(4),
  noShow(5),
  rejected(6);

  const BookingStatus(this.id);

  final int id;

  static BookingStatus fromId(int id) => values.firstWhere((status) => status.id == id);
}

enum SlotStatus {
  available('Available'),
  booked('Booked'),
  past('Past'),
  blocked('Blocked');

  const SlotStatus(this.value);

  final String value;

  static SlotStatus parse(String value) => values.firstWhere((status) => status.value == value);
}

enum BookingAction {
  confirm('confirm'),
  reject('reject'),
  cancel('cancel'),
  complete('complete'),
  noShow('no-show'),
  recordResult('record-result'),
  editResult('edit-result');

  const BookingAction(this.value);

  final String value;

  static BookingAction parse(String value) => values.firstWhere((action) => action.value == value);
}

enum NotificationType {
  bookingConfirmed('BookingConfirmed'),
  bookingCancelled('BookingCancelled'),
  sessionReminder('SessionReminder'),
  loyaltyPointsAwarded('LoyaltyPointsAwarded'),
  rewardRedeemed('RewardRedeemed'),
  bookingCreated('BookingCreated'),
  bookingRejected('BookingRejected'),
  bookingCompleted('BookingCompleted'),
  resultRecorded('ResultRecorded'),
  bookingNoShow('BookingNoShow');

  const NotificationType(this.value);

  final String value;

  static NotificationType parse(String value) => values.firstWhere((type) => type.value == value);
}

enum TransactionType {
  earned('Earned'),
  redeemed('Redeemed'),
  adjusted('Adjusted');

  const TransactionType(this.value);

  final String value;

  static TransactionType parse(String value) => values.firstWhere((type) => type.value == value);
}

enum RoomSort {
  rating('rating'),
  easiest('easiest'),
  hardest('hardest'),
  cheapest('cheapest'),
  popular('popular'),
  newest('newest');

  const RoomSort(this.value);

  final String value;
}

enum ListSort {
  newest('newest');

  const ListSort(this.value);

  final String value;
}

enum Weekday {
  monday('Monday'),
  tuesday('Tuesday'),
  wednesday('Wednesday'),
  thursday('Thursday'),
  friday('Friday'),
  saturday('Saturday'),
  sunday('Sunday');

  const Weekday(this.value);

  final String value;
}

enum ReportType {
  bookings('bookings'),
  revenue('revenue'),
  occupancy('occupancy'),
  topRooms('top-rooms'),
  topClients('top-clients'),
  topClientsBySpending('top-clients-by-spending'),
  ratings('ratings'),
  loyaltyRedemptions('loyalty-redemptions', adminOnly: true);

  const ReportType(this.value, {this.adminOnly = false});

  final String value;
  final bool adminOnly;
}

enum ReportGroupBy { day, month }

enum ExportFormat { pdf, csv }
