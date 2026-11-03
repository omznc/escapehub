import 'json.dart';

class ReviewDto {
  ReviewDto.fromJson(Json json)
    : id = json['id'] as int,
      roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      roomImageUrl = json['roomImageUrl'] as String?,
      clientId = json['clientId'] as int,
      clientName = json['clientName'] as String,
      clientPictureUrl = json['clientPictureUrl'] as String?,
      rating = json['rating'] as int,
      comment = json['comment'] as String?,
      isHidden = json['isHidden'] as bool,
      createdAt = readTimestamp(json['createdAt']),
      updatedAt = readTimestamp(json['updatedAt']);

  final int id;
  final int roomId;
  final String roomName;
  final String? roomImageUrl;
  final int clientId;
  final String clientName;
  final String? clientPictureUrl;
  final int rating;
  final String? comment;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;
}
