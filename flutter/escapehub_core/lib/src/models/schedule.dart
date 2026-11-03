import 'constants.dart';
import 'json.dart';

class ScheduleDto {
  ScheduleDto.fromJson(Json json)
    : id = json['id'] as int,
      roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      date = readDate(json['date']),
      startTime = json['startTime'] as String,
      endTime = json['endTime'] as String,
      isBlocked = json['isBlocked'] as bool,
      status = SlotStatus.parse(json['status'] as String),
      bookingId = json['bookingId'] as int?,
      bookingStatus = json['bookingStatus'] as String?,
      clientName = json['clientName'] as String?,
      canDelete = json['canDelete'] as bool,
      deleteBlockedReason = json['deleteBlockedReason'] as String?;

  final int id;
  final int roomId;
  final String roomName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isBlocked;
  final SlotStatus status;
  final int? bookingId;
  final String? bookingStatus;
  final String? clientName;
  final bool canDelete;
  final String? deleteBlockedReason;
}

class SlotDto {
  SlotDto.fromJson(Json json)
    : id = json['id'] as int,
      roomId = json['roomId'] as int,
      date = readDate(json['date']),
      startTime = json['startTime'] as String,
      endTime = json['endTime'] as String,
      status = SlotStatus.parse(json['status'] as String);

  final int id;
  final int roomId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final SlotStatus status;
}

class ScheduleRequest {
  const ScheduleRequest({
    required this.roomId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBlocked = false,
  });

  final int roomId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isBlocked;

  Json toJson() => {
    'roomId': roomId,
    'date': formatDate(date),
    'startTime': startTime,
    'endTime': endTime,
    'isBlocked': isBlocked,
  };
}

class GenerateSchedulesRequest {
  const GenerateSchedulesRequest({
    required this.roomId,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
    required this.breakMinutes,
    required this.daysOfWeek,
  });

  final int roomId;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final int breakMinutes;
  final Set<Weekday> daysOfWeek;

  Json toJson() => {
    'roomId': roomId,
    'startDate': formatDate(startDate),
    'endDate': formatDate(endDate),
    'startTime': startTime,
    'endTime': endTime,
    'slotDurationMinutes': slotDurationMinutes,
    'breakMinutes': breakMinutes,
    'daysOfWeek': [for (final day in daysOfWeek) day.value],
  };
}

class GenerateSchedulesResponse {
  GenerateSchedulesResponse.fromJson(Json json)
    : created = json['created'] as int,
      skipped = json['skipped'] as int,
      message = json['message'] as String;

  final int created;
  final int skipped;
  final String message;
}
