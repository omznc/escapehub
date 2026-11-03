import 'dart:typed_data';

import 'json.dart';

class ReportResult<T> {
  ReportResult.fromJson(Json json, T Function(Json json) parse)
    : title = json['title'] as String,
      from = readDate(json['from']),
      to = readDate(json['to']),
      rows = readList(json['rows'], parse);

  final String title;
  final DateTime from;
  final DateTime to;
  final List<T> rows;
}

class BookingsReportRow {
  BookingsReportRow.fromJson(Json json)
    : date = readDate(json['date']),
      total = json['total'] as int,
      pending = json['pending'] as int,
      confirmed = json['confirmed'] as int,
      completed = json['completed'] as int,
      cancelled = json['cancelled'] as int,
      noShow = json['noShow'] as int,
      rejected = json['rejected'] as int;

  final DateTime date;
  final int total;
  final int pending;
  final int confirmed;
  final int completed;
  final int cancelled;
  final int noShow;
  final int rejected;
}

class RevenueReportRow {
  RevenueReportRow.fromJson(Json json)
    : period = json['period'] as String,
      bookings = json['bookings'] as int,
      revenue = readDecimal(json['revenue']),
      discounts = readDecimal(json['discounts']);

  final String period;
  final int bookings;
  final double revenue;
  final double discounts;
}

class OccupancyReportRow {
  OccupancyReportRow.fromJson(Json json)
    : roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      totalSlots = json['totalSlots'] as int,
      bookedSlots = json['bookedSlots'] as int,
      occupancyPercent = readDecimal(json['occupancyPercent']);

  final int roomId;
  final String roomName;
  final int totalSlots;
  final int bookedSlots;
  final double occupancyPercent;
}

class TopRoomReportRow {
  TopRoomReportRow.fromJson(Json json)
    : roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      bookings = json['bookings'] as int,
      revenue = readDecimal(json['revenue']),
      averagePlayers = readDecimal(json['averagePlayers']);

  final int roomId;
  final String roomName;
  final int bookings;
  final double revenue;
  final double averagePlayers;
}

class TopClientReportRow {
  TopClientReportRow.fromJson(Json json)
    : clientId = json['clientId'] as int,
      clientName = json['clientName'] as String,
      email = json['email'] as String,
      bookings = json['bookings'] as int,
      totalSpent = readDecimal(json['totalSpent']);

  final int clientId;
  final String clientName;
  final String email;
  final int bookings;
  final double totalSpent;
}

class RatingReportRow {
  RatingReportRow.fromJson(Json json)
    : roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      averageRating = readDecimal(json['averageRating']),
      reviewCount = json['reviewCount'] as int,
      oneStar = json['oneStar'] as int,
      twoStars = json['twoStars'] as int,
      threeStars = json['threeStars'] as int,
      fourStars = json['fourStars'] as int,
      fiveStars = json['fiveStars'] as int;

  final int roomId;
  final String roomName;
  final double averageRating;
  final int reviewCount;
  final int oneStar;
  final int twoStars;
  final int threeStars;
  final int fourStars;
  final int fiveStars;
}

class RedemptionReportRow {
  RedemptionReportRow.fromJson(Json json)
    : rewardId = json['rewardId'] as int,
      rewardName = json['rewardName'] as String,
      redemptions = json['redemptions'] as int,
      pointsSpent = json['pointsSpent'] as int,
      used = json['used'] as int,
      unused = json['unused'] as int;

  final int rewardId;
  final String rewardName;
  final int redemptions;
  final int pointsSpent;
  final int used;
  final int unused;
}

class ExportedFile {
  const ExportedFile({required this.bytes, required this.fileName, required this.contentType});

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

class DashboardStatsDto {
  DashboardStatsDto.fromJson(Json json)
    : todayBookings = json['todayBookings'] as int,
      weekBookings = json['weekBookings'] as int,
      monthlyRevenue = readDecimal(json['monthlyRevenue']),
      averageRating = readDecimal(json['averageRating']),
      activePromotions = json['activePromotions'] as int,
      activeRooms = json['activeRooms'] as int,
      pendingBookings = json['pendingBookings'] as int,
      bookingsByDay = readList(json['bookingsByDay'], DayCountDto.fromJson),
      revenueByRoom = readList(json['revenueByRoom'], RoomValueDto.fromJson),
      occupancyByRoom = readList(json['occupancyByRoom'], RoomValueDto.fromJson),
      topClients = readList(json['topClients'], TopClientDto.fromJson),
      latestReviews = readList(json['latestReviews'], DashboardReviewDto.fromJson),
      upcomingSessions = readList(json['upcomingSessions'], UpcomingSessionDto.fromJson);

  final int todayBookings;
  final int weekBookings;
  final double monthlyRevenue;
  final double averageRating;
  final int activePromotions;
  final int activeRooms;
  final int pendingBookings;
  final List<DayCountDto> bookingsByDay;
  final List<RoomValueDto> revenueByRoom;
  final List<RoomValueDto> occupancyByRoom;
  final List<TopClientDto> topClients;
  final List<DashboardReviewDto> latestReviews;
  final List<UpcomingSessionDto> upcomingSessions;
}

class DayCountDto {
  DayCountDto.fromJson(Json json) : date = readDate(json['date']), count = json['count'] as int;

  final DateTime date;
  final int count;
}

class RoomValueDto {
  RoomValueDto.fromJson(Json json)
    : roomId = json['roomId'] as int,
      roomName = json['roomName'] as String,
      value = readDecimal(json['value']);

  final int roomId;
  final String roomName;
  final double value;
}

class TopClientDto {
  TopClientDto.fromJson(Json json)
    : clientId = json['clientId'] as int,
      clientName = json['clientName'] as String,
      bookings = json['bookings'] as int,
      totalSpent = readDecimal(json['totalSpent']);

  final int clientId;
  final String clientName;
  final int bookings;
  final double totalSpent;
}

class DashboardReviewDto {
  DashboardReviewDto.fromJson(Json json)
    : id = json['id'] as int,
      roomName = json['roomName'] as String,
      clientName = json['clientName'] as String,
      rating = json['rating'] as int,
      comment = json['comment'] as String?,
      isHidden = json['isHidden'] as bool,
      createdAt = readTimestamp(json['createdAt']);

  final int id;
  final String roomName;
  final String clientName;
  final int rating;
  final String? comment;
  final bool isHidden;
  final DateTime createdAt;
}

class UpcomingSessionDto {
  UpcomingSessionDto.fromJson(Json json)
    : bookingId = json['bookingId'] as int,
      roomName = json['roomName'] as String,
      clientName = json['clientName'] as String,
      date = readDate(json['date']),
      startTime = json['startTime'] as String,
      playerCount = json['playerCount'] as int,
      status = json['status'] as String;

  final int bookingId;
  final String roomName;
  final String clientName;
  final DateTime date;
  final String startTime;
  final int playerCount;
  final String status;
}
