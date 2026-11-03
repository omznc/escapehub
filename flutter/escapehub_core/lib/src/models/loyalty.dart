import 'constants.dart';
import 'json.dart';

class LoyaltyBalanceDto {
  LoyaltyBalanceDto.fromJson(Json json)
    : balance = json['balance'] as int,
      earnedTotal = json['earnedTotal'] as int,
      redeemedTotal = json['redeemedTotal'] as int;

  final int balance;
  final int earnedTotal;
  final int redeemedTotal;
}

class LoyaltyRewardDto {
  LoyaltyRewardDto.fromJson(Json json)
    : id = json['id'] as int,
      name = json['name'] as String,
      description = json['description'] as String,
      pointsCost = json['pointsCost'] as int,
      rewardTypeId = json['rewardTypeId'] as int,
      rewardTypeName = json['rewardTypeName'] as String,
      isPercentage = json['isPercentage'] as bool,
      value = readDecimal(json['value']),
      isActive = json['isActive'] as bool,
      redemptionCount = json['redemptionCount'] as int,
      canDelete = json['canDelete'] as bool?,
      deleteBlockedReason = json['deleteBlockedReason'] as String?;

  final int id;
  final String name;
  final String description;
  final int pointsCost;
  final int rewardTypeId;
  final String rewardTypeName;
  final bool isPercentage;
  final double value;
  final bool isActive;
  final int redemptionCount;
  final bool? canDelete;
  final String? deleteBlockedReason;
}

class LoyaltyTransactionDto {
  LoyaltyTransactionDto.fromJson(Json json)
    : id = json['id'] as int,
      clientId = json['clientId'] as int,
      clientName = json['clientName'] as String,
      clientPictureUrl = json['clientPictureUrl'] as String?,
      points = json['points'] as int,
      type = TransactionType.parse(json['transactionType'] as String),
      description = json['description'] as String?,
      bookingId = json['bookingId'] as int?,
      roomName = json['roomName'] as String?,
      roomImageUrl = json['roomImageUrl'] as String?,
      createdAt = readTimestamp(json['createdAt']);

  final int id;
  final int clientId;
  final String clientName;
  final String? clientPictureUrl;
  final int points;
  final TransactionType type;
  final String? description;
  final int? bookingId;
  final String? roomName;
  final String? roomImageUrl;
  final DateTime createdAt;
}

class RewardRedemptionDto {
  RewardRedemptionDto.fromJson(Json json)
    : id = json['id'] as int,
      clientId = json['clientId'] as int,
      clientName = json['clientName'] as String,
      clientPictureUrl = json['clientPictureUrl'] as String?,
      rewardId = json['rewardId'] as int,
      rewardName = json['rewardName'] as String,
      rewardTypeName = json['rewardTypeName'] as String,
      isPercentage = json['isPercentage'] as bool,
      value = readDecimal(json['value']),
      pointsSpent = json['pointsSpent'] as int,
      code = json['code'] as String,
      isUsed = json['isUsed'] as bool,
      usedAt = readTimestampOrNull(json['usedAt']),
      bookingId = json['bookingId'] as int?,
      redeemedAt = readTimestamp(json['redeemedAt']);

  final int id;
  final int clientId;
  final String clientName;
  final String? clientPictureUrl;
  final int rewardId;
  final String rewardName;
  final String rewardTypeName;
  final bool isPercentage;
  final double value;
  final int pointsSpent;
  final String code;
  final bool isUsed;
  final DateTime? usedAt;
  final int? bookingId;
  final DateTime redeemedAt;
}

class SaveLoyaltyRewardRequest {
  const SaveLoyaltyRewardRequest({
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.rewardTypeId,
    required this.value,
    required this.isActive,
  });

  final String name;
  final String description;
  final int pointsCost;
  final int rewardTypeId;
  final double value;
  final bool isActive;

  Json toJson() => {
    'name': name,
    'description': description,
    'pointsCost': pointsCost,
    'rewardTypeId': rewardTypeId,
    'value': value,
    'isActive': isActive,
  };
}
