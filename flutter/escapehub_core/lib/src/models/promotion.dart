import 'json.dart';

class PromotionDto {
  PromotionDto.fromJson(Json json)
    : id = json['id'] as int,
      name = json['name'] as String,
      description = json['description'] as String,
      promotionTypeId = json['promotionTypeId'] as int,
      promotionTypeName = json['promotionTypeName'] as String,
      isPercentage = json['isPercentage'] as bool,
      discountValue = readDecimal(json['discountValue']),
      startDate = readDate(json['startDate']),
      endDate = readDate(json['endDate']),
      isActive = json['isActive'] as bool,
      isCurrentlyValid = json['isCurrentlyValid'] as bool,
      appliesToAllRooms = json['appliesToAllRooms'] as bool,
      rooms = readList(json['rooms'], PromotionRoomDto.fromJson),
      bookingCount = json['bookingCount'] as int?,
      canDelete = json['canDelete'] as bool?,
      deleteBlockedReason = json['deleteBlockedReason'] as String?;

  final int id;
  final String name;
  final String description;
  final int promotionTypeId;
  final String promotionTypeName;
  final bool isPercentage;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isCurrentlyValid;
  final bool appliesToAllRooms;
  final List<PromotionRoomDto> rooms;
  final int? bookingCount;
  final bool? canDelete;
  final String? deleteBlockedReason;
}

class PromotionRoomDto {
  PromotionRoomDto.fromJson(Json json) : id = json['id'] as int, name = json['name'] as String;

  final int id;
  final String name;
}

class SavePromotionRequest {
  const SavePromotionRequest({
    required this.name,
    required this.description,
    required this.promotionTypeId,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.roomIds = const [],
  });

  final String name;
  final String description;
  final int promotionTypeId;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<int> roomIds;

  Json toJson() => {
    'name': name,
    'description': description,
    'promotionTypeId': promotionTypeId,
    'discountValue': discountValue,
    'startDate': formatDate(startDate),
    'endDate': formatDate(endDate),
    'isActive': isActive,
    'roomIds': roomIds,
  };
}
