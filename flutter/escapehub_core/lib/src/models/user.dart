import 'constants.dart';
import 'json.dart';

class UserDto {
  UserDto.fromJson(Json json)
    : id = json['id'] as int,
      username = json['username'] as String,
      email = json['email'] as String,
      firstName = json['firstName'] as String,
      lastName = json['lastName'] as String,
      phone = json['phone'] as String?,
      profilePictureUrl = json['profilePictureUrl'] as String?,
      isActive = json['isActive'] as bool,
      role = json['role'] as String,
      cityId = json['cityId'] as int?,
      cityName = json['cityName'] as String?,
      countryId = json['countryId'] as int?,
      countryName = json['countryName'] as String?,
      createdAt = readTimestamp(json['createdAt']);

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profilePictureUrl;
  final bool isActive;
  final String role;
  final int? cityId;
  final String? cityName;
  final int? countryId;
  final String? countryName;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';

  bool get isAdministrator => role == Roles.administrator;

  bool get isRoomManager => role == Roles.roomManager;

  bool get isClient => role == Roles.client;
}

class AuthResponse {
  AuthResponse.fromJson(Json json) : token = json['token'] as String;

  final String token;
}

class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.cityId,
  });

  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  final int? cityId;

  Json toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'cityId': cityId,
  };
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.cityId,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final int? cityId;

  Json toJson() => {'firstName': firstName, 'lastName': lastName, 'email': email, 'phone': phone, 'cityId': cityId};
}

class CreateUserRequest {
  const CreateUserRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.cityId,
  });

  final String username;
  final String password;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final int? cityId;

  Json toJson() => {
    'username': username,
    'password': password,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'cityId': cityId,
    'role': role,
  };
}

class UpdateUserRequest {
  const UpdateUserRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.cityId,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final int? cityId;

  Json toJson() => {
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'cityId': cityId,
    'role': role,
  };
}
