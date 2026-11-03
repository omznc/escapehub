import 'json.dart';

class SettingsDto {
  SettingsDto.fromJson(Json json)
    : companyName = json['companyName'] as String,
      contactEmail = json['contactEmail'] as String,
      contactPhone = json['contactPhone'] as String?,
      pointsPerPlayer = json['pointsPerPlayer'] as int,
      pointsPerCurrencyUnit = readDecimal(json['pointsPerCurrencyUnit']),
      cancellationDeadlineHours = json['cancellationDeadlineHours'] as int,
      reminderHoursBefore = json['reminderHoursBefore'] as int,
      updatedAt = readTimestamp(json['updatedAt']),
      updatedByName = json['updatedByName'] as String?;

  final String companyName;
  final String contactEmail;
  final String? contactPhone;
  final int pointsPerPlayer;
  final double pointsPerCurrencyUnit;
  final int cancellationDeadlineHours;
  final int reminderHoursBefore;
  final DateTime updatedAt;
  final String? updatedByName;
}

class UpdateSettingsRequest {
  const UpdateSettingsRequest({
    required this.companyName,
    required this.contactEmail,
    required this.pointsPerPlayer,
    required this.pointsPerCurrencyUnit,
    required this.cancellationDeadlineHours,
    required this.reminderHoursBefore,
    this.contactPhone,
  });

  final String companyName;
  final String contactEmail;
  final int pointsPerPlayer;
  final double pointsPerCurrencyUnit;
  final int cancellationDeadlineHours;
  final int reminderHoursBefore;
  final String? contactPhone;

  Json toJson() => {
    'companyName': companyName,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'pointsPerPlayer': pointsPerPlayer,
    'pointsPerCurrencyUnit': pointsPerCurrencyUnit,
    'cancellationDeadlineHours': cancellationDeadlineHours,
    'reminderHoursBefore': reminderHoursBefore,
  };
}
