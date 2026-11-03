import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../widgets/actions.dart';

Future<bool> toggleRoomArchive(BuildContext context, WidgetRef ref, RoomListItemDto room) async {
  final api = ref.read(apiClientProvider).rooms;
  final archive = room.isActive;
  final done = await confirmAndRun(
    context,
    title: archive ? 'Archive the room' : 'Restore the room',
    message: archive
        ? 'Do you want to archive the room ${room.name}? Clients cannot see or book an archived room.'
        : 'Do you want to restore the room ${room.name}? Clients can see and book the room again.',
    confirmLabel: archive ? 'Archive' : 'Restore',
    destructive: archive,
    action: () => archive ? api.archive(room.id) : api.restore(room.id),
    success: archive ? 'The room ${room.name} was archived.' : 'The room ${room.name} was restored.',
  );
  if (done && context.mounted) ref.invalidate(roomOptionsProvider);
  return done;
}

Future<bool> deleteRoom(BuildContext context, WidgetRef ref, RoomListItemDto room) async {
  final done = await confirmAndRun(
    context,
    title: 'Delete the room',
    message: 'Do you want to delete the room ${room.name}? You cannot undo this action.',
    confirmLabel: 'Delete',
    destructive: true,
    action: () => ref.read(apiClientProvider).rooms.delete(room.id),
    success: 'The room ${room.name} was deleted.',
  );
  if (done && context.mounted) ref.invalidate(roomOptionsProvider);
  return done;
}
