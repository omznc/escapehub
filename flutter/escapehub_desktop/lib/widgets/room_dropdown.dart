import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'form_fields.dart';

class RoomDropdown extends ConsumerWidget {
  const RoomDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.activeOnly = false,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final FormFieldValidator<int>? validator;
  final bool enabled;
  final bool activeOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(roomOptionsProvider);
    final rooms = [
      for (final room in options.value ?? const <RoomListItemDto>[])
        if (room.isActive || !activeOnly) room,
    ];
    return DropdownButtonFormField<int>(
      key: ValueKey('room-$value-${rooms.length}'),
      initialValue: rooms.any((room) => room.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Room',
        prefixIcon: const Icon(Icons.meeting_room_outlined),
        helperText: listError(options.error),
      ),
      validator: validator,
      onChanged: enabled ? onChanged : null,
      items: [
        for (final room in rooms)
          DropdownMenuItem(value: room.id, child: Text(room.isActive ? room.name : '${room.name} (archived)')),
      ],
    );
  }
}

String? noRoomsReason(WidgetRef ref, String item) {
  final rooms = ref.watch(roomOptionsProvider).value;
  return rooms != null && rooms.isEmpty ? 'Add a room first. Each $item belongs to a room.' : null;
}
