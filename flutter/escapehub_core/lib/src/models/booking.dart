import 'constants.dart';
import 'json.dart';

class BookingListItemDto {
  BookingListItemDto.fromJson(Json json)
    : id = json['id'] as int,
      roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      roomImageUrl = json['roomImageUrl'] as String?,
      themeName = json['themeName'] as String,
      scheduleId = json['scheduleId'] as int,
      date = readDate(json['date']),
      startTime = json['startTime'] as String,
      endTime = json['endTime'] as String,
      clientId = json['clientId'] as int,
      clientName = json['clientName'] as String,
      clientPictureUrl = json['clientPictureUrl'] as String?,
      status = BookingStatus.fromId(json['statusId'] as int),
      statusName = json['status'] as String,
      playerCount = json['playerCount'] as int,
      totalPrice = readDecimal(json['totalPrice']),
      hasResult = json['hasResult'] as bool,
      isPaid = json['isPaid'] as bool? ?? false,
      createdAt = readTimestamp(json['createdAt']);

  final int id;
  final int roomId;
  final String roomName;
  final String? roomImageUrl;
  final String themeName;
  final int scheduleId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int clientId;
  final String clientName;
  final String? clientPictureUrl;
  final BookingStatus status;
  final String statusName;
  final int playerCount;
  final double totalPrice;
  final bool hasResult;
  final bool isPaid;
  final DateTime createdAt;
}

class BookingDto extends BookingListItemDto {
  BookingDto.fromJson(super.json)
    : clientEmail = json['clientEmail'] as String,
      subtotal = readDecimal(json['subtotal']),
      discountApplied = readDecimal(json['discountApplied']),
      promotionId = json['promotionId'] as int?,
      promotionName = json['promotionName'] as String?,
      redemptionId = json['redemptionId'] as int?,
      voucherCode = json['voucherCode'] as String?,
      rewardName = json['rewardName'] as String?,
      notes = json['notes'] as String?,
      participantNames = readStrings(json['participantNames']),
      result = json['result'] == null ? null : RoomResultDto.fromJson(json['result'] as Json),
      pointsEarned = json['pointsEarned'] as int,
      canCancel = json['canCancel'] as bool,
      cancelBlockedReason = json['cancelBlockedReason'] as String?,
      canReview = json['canReview'] as bool,
      paymentStatus = json['paymentStatus'] as String?,
      paidAt = readTimestampOrNull(json['paidAt']),
      paidAmount = readDecimalOrNull(json['paidAmount']),
      refundedAt = readTimestampOrNull(json['refundedAt']),
      refundedAmount = readDecimalOrNull(json['refundedAmount']),
      canPay = json['canPay'] as bool? ?? false,
      payBlockedReason = json['payBlockedReason'] as String?,
      allowedActions = {for (final action in readStrings(json['allowedActions'])) BookingAction.parse(action)},
      blockedReasons = Map<String, String>.from(json['blockedReasons'] as Map),
      statusHistory = readList(json['statusHistory'], BookingStatusHistoryDto.fromJson),
      super.fromJson();

  final String clientEmail;
  final double subtotal;
  final double discountApplied;
  final int? promotionId;
  final String? promotionName;
  final int? redemptionId;
  final String? voucherCode;
  final String? rewardName;
  final String? notes;
  final List<String> participantNames;
  final RoomResultDto? result;
  final int pointsEarned;
  final bool canCancel;
  final String? cancelBlockedReason;
  final bool canReview;
  final String? paymentStatus;
  final DateTime? paidAt;
  final double? paidAmount;
  final DateTime? refundedAt;
  final double? refundedAmount;
  final bool canPay;
  final String? payBlockedReason;
  final Set<BookingAction> allowedActions;
  final Map<String, String> blockedReasons;
  final List<BookingStatusHistoryDto> statusHistory;

  bool allows(BookingAction action) => allowedActions.contains(action);

  String? blockedReason(BookingAction action) => blockedReasons[action.value];
}

class PaymentStart {
  PaymentStart.fromJson(Json json)
    : paymentId = json['paymentId'] as int,
      checkoutUrl = json['checkoutUrl'] as String,
      returnUrl = json['returnUrl'] as String;

  final int paymentId;
  final String checkoutUrl;
  final String returnUrl;
}

class RoomResultDto {
  RoomResultDto.fromJson(Json json)
    : escaped = json['escaped'] as bool,
      completionTimeMinutes = json['completionTimeMinutes'] as int?,
      hintsUsed = json['hintsUsed'] as int?,
      managerNotes = json['managerNotes'] as String?,
      score = json['score'] as int?,
      recordedByName = json['recordedByName'] as String,
      recordedAt = readTimestamp(json['recordedAt']);

  final bool escaped;
  final int? completionTimeMinutes;
  final int? hintsUsed;
  final String? managerNotes;
  final int? score;
  final String recordedByName;
  final DateTime recordedAt;
}

class BookingStatusHistoryDto {
  BookingStatusHistoryDto.fromJson(Json json)
    : fromStatus = json['fromStatus'] as String?,
      toStatus = json['toStatus'] as String,
      changedByName = json['changedByName'] as String?,
      reason = json['reason'] as String?,
      changedAt = readTimestamp(json['changedAt']);

  final String? fromStatus;
  final String toStatus;
  final String? changedByName;
  final String? reason;
  final DateTime changedAt;
}

class BookingQuoteDto {
  BookingQuoteDto.fromJson(Json json)
    : subtotal = readDecimal(json['subtotal']),
      promotionDiscount = readDecimal(json['promotionDiscount']),
      voucherDiscount = readDecimal(json['voucherDiscount']),
      discountApplied = readDecimal(json['discountApplied']),
      totalPrice = readDecimal(json['totalPrice']),
      promotionName = json['promotionName'] as String?,
      rewardName = json['rewardName'] as String?;

  final double subtotal;
  final double promotionDiscount;
  final double voucherDiscount;
  final double discountApplied;
  final double totalPrice;
  final String? promotionName;
  final String? rewardName;
}

class CreateBookingRequest {
  const CreateBookingRequest({
    required this.scheduleId,
    required this.playerCount,
    this.clientId,
    this.promotionId,
    this.redemptionId,
    this.voucherCode,
    this.notes,
    this.participantNames = const [],
  });

  final int scheduleId;
  final int playerCount;
  final int? clientId;
  final int? promotionId;
  final int? redemptionId;
  final String? voucherCode;
  final String? notes;
  final List<String> participantNames;

  Json toJson() => {
    'scheduleId': scheduleId,
    'clientId': clientId,
    'playerCount': playerCount,
    'promotionId': promotionId,
    'redemptionId': redemptionId,
    'voucherCode': voucherCode,
    'notes': notes,
    'participantNames': participantNames,
  };
}

class SaveRoomResultRequest {
  const SaveRoomResultRequest({
    required this.escaped,
    this.completionTimeMinutes,
    this.hintsUsed,
    this.managerNotes,
    this.score,
  });

  final bool escaped;
  final int? completionTimeMinutes;
  final int? hintsUsed;
  final String? managerNotes;
  final int? score;

  Json toJson() => {
    'escaped': escaped,
    'completionTimeMinutes': completionTimeMinutes,
    'hintsUsed': hintsUsed,
    'managerNotes': managerNotes,
    'score': score,
  };
}
