import 'json.dart';

enum ReferenceTable {
  themes('themes', ReferenceDto.fromJson),
  countries('countries', ReferenceDto.fromJson),
  cities('cities', CityDto.fromJson),
  difficultyLevels('difficulty-levels', DifficultyLevelDto.fromJson),
  bookingStatuses('booking-statuses', ReferenceDto.fromJson),
  promotionTypes('promotion-types', DiscountTypeDto.fromJson),
  rewardTypes('reward-types', DiscountTypeDto.fromJson);

  const ReferenceTable(this.path, this.parse);

  final String path;
  final ReferenceDto Function(Json json) parse;
}

class ReferenceDto {
  ReferenceDto.fromJson(Json json)
    : id = json['id'] as int,
      name = json['name'] as String,
      usageCount = json['usageCount'] as int,
      canDelete = json['canDelete'] as bool,
      deleteBlockedReason = json['deleteBlockedReason'] as String?;

  final int id;
  final String name;
  final int usageCount;
  final bool canDelete;
  final String? deleteBlockedReason;
}

class CityDto extends ReferenceDto {
  CityDto.fromJson(super.json)
    : countryId = json['countryId'] as int,
      countryName = json['countryName'] as String,
      super.fromJson();

  final int countryId;
  final String countryName;
}

class DifficultyLevelDto extends ReferenceDto {
  DifficultyLevelDto.fromJson(super.json) : value = json['value'] as int, super.fromJson();

  final int value;
}

class DiscountTypeDto extends ReferenceDto {
  DiscountTypeDto.fromJson(super.json) : isPercentage = json['isPercentage'] as bool, super.fromJson();

  final bool isPercentage;
}

class ReferenceRequest {
  const ReferenceRequest({required this.name});

  final String name;

  Json toJson() => {'name': name};
}

class CityRequest extends ReferenceRequest {
  const CityRequest({required super.name, required this.countryId});

  final int countryId;

  @override
  Json toJson() => {...super.toJson(), 'countryId': countryId};
}

class DifficultyLevelRequest extends ReferenceRequest {
  const DifficultyLevelRequest({required super.name, required this.value});

  final int value;

  @override
  Json toJson() => {...super.toJson(), 'value': value};
}

class DiscountTypeRequest extends ReferenceRequest {
  const DiscountTypeRequest({required super.name, required this.isPercentage});

  final bool isPercentage;

  @override
  Json toJson() => {...super.toJson(), 'isPercentage': isPercentage};
}
