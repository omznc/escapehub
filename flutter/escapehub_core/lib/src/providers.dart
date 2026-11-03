import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/api_exception.dart';
import 'models/reference.dart';
import 'models/user.dart';

Duration? _noRetry(int retryCount, Object error) => null;

final apiClientProvider = Provider<ApiClient>((ref) {
  final api = ApiClient();
  ref.onDispose(api.close);
  return api;
});

final sessionProvider = AsyncNotifierProvider<SessionNotifier, UserDto?>(SessionNotifier.new, retry: _noRetry);

final currentUserProvider = Provider<UserDto?>((ref) => ref.watch(sessionProvider).value);

class SessionNotifier extends AsyncNotifier<UserDto?> {
  static const _tokenKey = 'token';

  final _storage = SharedPreferencesAsync();
  late ApiClient _api;

  @override
  Future<UserDto?> build() async {
    _api = ref.watch(apiClientProvider);
    final subscription = _api.unauthorized.listen((_) => _end());
    ref.onDispose(subscription.cancel);
    final token = await _storage.getString(_tokenKey);
    if (token == null) return null;
    _api.token = token;
    try {
      return await _api.auth.me();
    } on ApiException catch (error) {
      if (!error.isUnauthorized) rethrow;
      await _clear();
      return null;
    }
  }

  Future<void> login(String username, String password) async => _start(await _api.auth.login(username, password));

  Future<void> desktopLogin(String username, String password) async =>
      _start(await _api.auth.desktopLogin(username, password));

  Future<void> register(RegisterRequest request) async => _start(await _api.auth.register(request));

  Future<void> logout() async {
    try {
      await _api.auth.logout();
    } finally {
      await _end();
    }
  }

  Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    final message = await _api.auth.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    await _end();
    return message;
  }

  Future<void> reload() async {
    final user = await _api.auth.me();
    state = AsyncData(user);
  }

  Future<UserDto> updateProfile(UpdateProfileRequest request) async {
    final user = await _api.auth.updateProfile(request);
    state = AsyncData(user);
    return user;
  }

  Future<void> _start(AuthResponse auth) async {
    _api.token = auth.token;
    final user = await _api.auth.me();
    await _storage.setString(_tokenKey, auth.token);
    state = AsyncData(user);
  }

  Future<void> _end() async {
    await _clear();
    state = const AsyncData(null);
  }

  Future<void> _clear() async {
    _api.token = null;
    await _storage.remove(_tokenKey);
  }
}

final unreadNotificationsProvider = AsyncNotifierProvider<UnreadNotificationsNotifier, int>(
  UnreadNotificationsNotifier.new,
  retry: _noRetry,
);

class UnreadNotificationsNotifier extends AsyncNotifier<int> {
  static const interval = Duration(seconds: 30);

  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<int> build() async {
    final userId = ref.watch(sessionProvider.select((session) => session.value?.id));
    if (userId == null) return 0;
    final timer = Timer.periodic(interval, (_) => refresh());
    ref.onDispose(timer.cancel);
    return _api.notifications.unreadCount();
  }

  Future<void> refresh() async {
    final count = await AsyncValue.guard(_api.notifications.unreadCount);
    if (ref.mounted) state = count;
  }

  Future<void> markRead(int id) async {
    await _api.notifications.markRead(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _api.notifications.markAllRead();
    if (ref.mounted) state = const AsyncData(0);
  }
}

final referenceProvider = FutureProvider.family<List<ReferenceDto>, ReferenceTable>((ref, table) async {
  final userId = ref.watch(sessionProvider.select((session) => session.value?.id));
  if (userId == null) return const [];
  final page = await ref.watch(apiClientProvider).references.list(table, pageSize: 100);
  return page.items;
}, retry: _noRetry);
