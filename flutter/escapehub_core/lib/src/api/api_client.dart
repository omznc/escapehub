import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/booking.dart';
import '../models/constants.dart';
import '../models/json.dart';
import '../models/loyalty.dart';
import '../models/notification.dart';
import '../models/paged.dart';
import '../models/promotion.dart';
import '../models/reference.dart';
import '../models/report.dart';
import '../models/review.dart';
import '../models/room.dart';
import '../models/schedule.dart';
import '../models/settings.dart';
import '../models/user.dart';
import 'api_exception.dart';

part 'auth_api.dart';
part 'bookings_api.dart';
part 'files_api.dart';
part 'loyalty_api.dart';
part 'notifications_api.dart';
part 'promotions_api.dart';
part 'references_api.dart';
part 'reports_api.dart';
part 'reviews_api.dart';
part 'rooms_api.dart';
part 'schedules_api.dart';
part 'settings_api.dart';
part 'users_api.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000');

class ApiClient {
  ApiClient({String baseUrl = apiBaseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(authHeaders);
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final _unauthorized = StreamController<void>.broadcast();

  String? token;

  late final auth = AuthApi._(this);
  late final bookings = BookingsApi._(this);
  late final clients = ClientsApi._(this);
  late final dashboard = DashboardApi._(this);
  late final files = FilesApi._(this);
  late final loyalty = LoyaltyApi._(this);
  late final notifications = NotificationsApi._(this);
  late final promotions = PromotionsApi._(this);
  late final recommendations = RecommendationsApi._(this);
  late final references = ReferencesApi._(this);
  late final reports = ReportsApi._(this);
  late final reviews = ReviewsApi._(this);
  late final rooms = RoomsApi._(this);
  late final scenarios = RoomScenariosApi._(this);
  late final schedules = SchedulesApi._(this);
  late final settings = SettingsApi._(this);
  late final users = UsersApi._(this);

  String get baseUrl => _dio.options.baseUrl;

  Stream<void> get unauthorized => _unauthorized.stream;

  Map<String, String> get authHeaders => token == null ? const {} : {'Authorization': 'Bearer $token'};

  String fileUrl(String path) => Uri.parse(baseUrl).resolve(path).toString();

  Map<String, String> headersFor(String url) {
    final api = Uri.parse(baseUrl);
    final target = Uri.parse(url);
    final sameOrigin = target.scheme == api.scheme && target.host == api.host && target.port == api.port;
    return sameOrigin ? authHeaders : const {};
  }

  void close() {
    _unauthorized.close();
    _dio.close();
  }

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);
      final sentAuthorization = error.requestOptions.headers['Authorization'];
      if (exception.isUnauthorized && sentAuthorization != null && sentAuthorization == authHeaders['Authorization']) {
        _unauthorized.add(null);
      }
      throw exception;
    }
  }

  Future<T> _get<T>(String path, T Function(Json json) parse, [Map<String, Object?> query = const {}]) async {
    final response = await _send(() => _dio.get<Json>(path, queryParameters: _query(query)));
    return parse(response.data!);
  }

  Future<Paged<T>> _getPaged<T>(String path, T Function(Json json) parse, Map<String, Object?> query) =>
      _get(path, (json) => Paged.fromJson(json, parse), query);

  Future<T> _post<T>(String path, T Function(Json json) parse, [Object? body]) async {
    final response = await _send(() => _dio.post<Json>(path, data: body));
    return parse(response.data!);
  }

  Future<T> _put<T>(String path, T Function(Json json) parse, Object body) async {
    final response = await _send(() => _dio.put<Json>(path, data: body));
    return parse(response.data!);
  }

  Future<void> _command(String path, [Object? body]) => _send(() => _dio.post<void>(path, data: body));

  Future<void> _delete(String path) => _send(() => _dio.delete<void>(path));

  Future<String> _upload(String path, Uint8List bytes, String fileName) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName, contentType: _imageType(fileName)),
    });
    final response = await _send(() => _dio.post<Json>(path, data: form));
    return response.data!['url'] as String;
  }

  static Map<String, Object> _query(Map<String, Object?> values) => {
    for (final MapEntry(:key, :value) in values.entries)
      if (value != null) key: value is DateTime ? formatDate(value) : value,
  };

  static DioMediaType _imageType(String fileName) => switch (fileName.split('.').last.toLowerCase()) {
    'png' => DioMediaType('image', 'png'),
    'webp' => DioMediaType('image', 'webp'),
    _ => DioMediaType('image', 'jpeg'),
  };
}

String _message(Json json) => json['message'] as String;

int _count(Json json) => json['count'] as int;
