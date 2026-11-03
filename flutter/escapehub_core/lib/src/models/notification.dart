import 'constants.dart';
import 'json.dart';

class NotificationDto {
  NotificationDto.fromJson(Json json)
    : id = json['id'] as int,
      title = json['title'] as String,
      message = json['message'] as String,
      type = NotificationType.parse(json['type'] as String),
      isRead = json['isRead'] as bool,
      createdAt = readTimestamp(json['createdAt']);

  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
}
