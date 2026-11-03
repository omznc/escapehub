import 'json.dart';

class RoomListItemDto {
  RoomListItemDto.fromJson(Json json)
    : id = json['id'] as int,
      name = json['name'] as String,
      shortDescription = json['shortDescription'] as String,
      themeId = json['themeId'] as int,
      themeName = json['themeName'] as String,
      difficultyLevelId = json['difficultyLevelId'] as int,
      difficultyName = json['difficultyName'] as String,
      difficultyValue = json['difficultyValue'] as int,
      minPlayers = json['minPlayers'] as int,
      maxPlayers = json['maxPlayers'] as int,
      durationMinutes = json['durationMinutes'] as int,
      pricePerPerson = readDecimal(json['pricePerPerson']),
      pricePerBooking = readDecimal(json['pricePerBooking']),
      imageUrl = json['imageUrl'] as String?,
      isActive = json['isActive'] as bool,
      cityId = json['cityId'] as int?,
      cityName = json['cityName'] as String?,
      managerId = json['managerId'] as int?,
      managerName = json['managerName'] as String?,
      averageRating = readDecimal(json['averageRating']),
      reviewCount = json['reviewCount'] as int,
      bookingCount = json['bookingCount'] as int?,
      canDelete = json['canDelete'] as bool?,
      deleteBlockedReason = json['deleteBlockedReason'] as String?;

  final int id;
  final String name;
  final String shortDescription;
  final int themeId;
  final String themeName;
  final int difficultyLevelId;
  final String difficultyName;
  final int difficultyValue;
  final int minPlayers;
  final int maxPlayers;
  final int durationMinutes;
  final double pricePerPerson;
  final double pricePerBooking;
  final String? imageUrl;
  final bool isActive;
  final int? cityId;
  final String? cityName;
  final int? managerId;
  final String? managerName;
  final double averageRating;
  final int reviewCount;
  final int? bookingCount;
  final bool? canDelete;
  final String? deleteBlockedReason;
}

class RoomDto extends RoomListItemDto {
  RoomDto.fromJson(super.json)
    : longDescription = json['longDescription'] as String,
      ageRecommendation = json['ageRecommendation'] as String?,
      scenarios = readList(json['scenarios'], RoomScenarioSummaryDto.fromJson),
      super.fromJson();

  final String longDescription;
  final String? ageRecommendation;
  final List<RoomScenarioSummaryDto> scenarios;
}

class RoomScenarioSummaryDto {
  RoomScenarioSummaryDto.fromJson(Json json)
    : id = json['id'] as int,
      name = json['name'] as String,
      story = json['story'] as String,
      difficultyName = json['difficultyName'] as String?,
      hintPolicy = json['hintPolicy'] as String?;

  final int id;
  final String name;
  final String story;
  final String? difficultyName;
  final String? hintPolicy;
}

class RoomScenarioDto {
  RoomScenarioDto.fromJson(Json json)
    : id = json['id'] as int,
      roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      roomImageUrl = json['roomImageUrl'] as String?,
      name = json['name'] as String,
      story = json['story'] as String,
      difficultyOverrideId = json['difficultyOverrideId'] as int?,
      difficultyName = json['difficultyName'] as String?,
      hintPolicy = json['hintPolicy'] as String?,
      isActive = json['isActive'] as bool;

  final int id;
  final int roomId;
  final String roomName;
  final String? roomImageUrl;
  final String name;
  final String story;
  final int? difficultyOverrideId;
  final String? difficultyName;
  final String? hintPolicy;
  final bool isActive;
}

class RoomStatsDto {
  RoomStatsDto.fromJson(Json json)
    : roomId = json['roomId'] as int,
      from = readDate(json['from']),
      to = readDate(json['to']),
      totalBookings = json['totalBookings'] as int,
      completedBookings = json['completedBookings'] as int,
      cancelledBookings = json['cancelledBookings'] as int,
      revenue = readDecimal(json['revenue']),
      averageRating = readDecimal(json['averageRating']),
      reviewCount = json['reviewCount'] as int,
      totalSlots = json['totalSlots'] as int,
      bookedSlots = json['bookedSlots'] as int,
      occupancyPercent = readDecimal(json['occupancyPercent']),
      recordedResults = json['recordedResults'] as int,
      escapeRatePercent = readDecimal(json['escapeRatePercent']),
      averageCompletionMinutes = readDecimalOrNull(json['averageCompletionMinutes']);

  final int roomId;
  final DateTime from;
  final DateTime to;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double revenue;
  final double averageRating;
  final int reviewCount;
  final int totalSlots;
  final int bookedSlots;
  final double occupancyPercent;
  final int recordedResults;
  final double escapeRatePercent;
  final double? averageCompletionMinutes;
}

class RecommendationDto {
  RecommendationDto.fromJson(Json json)
    : roomId = json['roomId'] as int,
      name = json['name'] as String,
      shortDescription = json['shortDescription'] as String,
      imageUrl = json['imageUrl'] as String?,
      themeName = json['themeName'] as String,
      difficultyName = json['difficultyName'] as String,
      minPlayers = json['minPlayers'] as int,
      maxPlayers = json['maxPlayers'] as int,
      durationMinutes = json['durationMinutes'] as int,
      pricePerPerson = readDecimal(json['pricePerPerson']),
      pricePerBooking = readDecimal(json['pricePerBooking']),
      averageRating = readDecimal(json['averageRating']),
      reviewCount = json['reviewCount'] as int,
      score = readDecimal(json['score']),
      alreadyPlayed = json['alreadyPlayed'] as bool,
      reason = json['reason'] as String;

  final int roomId;
  final String name;
  final String shortDescription;
  final String? imageUrl;
  final String themeName;
  final String difficultyName;
  final int minPlayers;
  final int maxPlayers;
  final int durationMinutes;
  final double pricePerPerson;
  final double pricePerBooking;
  final double averageRating;
  final int reviewCount;
  final double score;
  final bool alreadyPlayed;
  final String reason;
}

class SaveRoomRequest {
  const SaveRoomRequest({
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.themeId,
    required this.difficultyLevelId,
    required this.minPlayers,
    required this.maxPlayers,
    required this.durationMinutes,
    required this.pricePerPerson,
    required this.pricePerBooking,
    required this.isActive,
    this.ageRecommendation,
    this.cityId,
    this.managerId,
  });

  final String name;
  final String shortDescription;
  final String longDescription;
  final int themeId;
  final int difficultyLevelId;
  final int minPlayers;
  final int maxPlayers;
  final int durationMinutes;
  final double pricePerPerson;
  final double pricePerBooking;
  final bool isActive;
  final String? ageRecommendation;
  final int? cityId;
  final int? managerId;

  Json toJson() => {
    'name': name,
    'shortDescription': shortDescription,
    'longDescription': longDescription,
    'themeId': themeId,
    'difficultyLevelId': difficultyLevelId,
    'minPlayers': minPlayers,
    'maxPlayers': maxPlayers,
    'durationMinutes': durationMinutes,
    'pricePerPerson': pricePerPerson,
    'pricePerBooking': pricePerBooking,
    'isActive': isActive,
    'ageRecommendation': ageRecommendation,
    'cityId': cityId,
    'managerId': managerId,
  };
}

class SaveRoomScenarioRequest {
  const SaveRoomScenarioRequest({
    required this.roomId,
    required this.name,
    required this.story,
    required this.isActive,
    this.difficultyOverrideId,
    this.hintPolicy,
  });

  final int roomId;
  final String name;
  final String story;
  final bool isActive;
  final int? difficultyOverrideId;
  final String? hintPolicy;

  Json toJson() => {
    'roomId': roomId,
    'name': name,
    'story': story,
    'difficultyOverrideId': difficultyOverrideId,
    'hintPolicy': hintPolicy,
    'isActive': isActive,
  };
}
