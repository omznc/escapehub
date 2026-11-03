import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/shell/section.dart';

Duration? _noRetry(int retryCount, Object error) => null;

final sectionProvider = NotifierProvider<SectionNotifier, Section>(SectionNotifier.new);

class SectionNotifier extends Notifier<Section> {
  @override
  Section build() {
    ref.watch(sessionProvider.select((session) => session.value?.id));
    return Section.dashboard;
  }

  void open(Section section) => state = section;

  @override
  bool updateShouldNotify(Section previous, Section next) => true;
}

final roomOptionsProvider = FutureProvider<List<RoomListItemDto>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final managerId = user.isRoomManager ? user.id : null;
  final page = await ref.watch(apiClientProvider).rooms.list(RoomQuery(managerId: managerId, pageSize: 100));
  return page.items;
}, retry: _noRetry);

final managerOptionsProvider = FutureProvider<List<UserDto>>((ref) async {
  final userId = ref.watch(sessionProvider.select((session) => session.value?.id));
  if (userId == null) return const [];
  final page = await ref.watch(apiClientProvider).users.list(role: Roles.roomManager, isActive: true, pageSize: 100);
  return page.items;
}, retry: _noRetry);
