import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../parallel.dart';
import '../../providers.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/pages.dart';
import '../../widgets/room_dropdown.dart';

Future<BookingDto?> showBookingCreateDialog(BuildContext context) =>
    showDialog<BookingDto>(context: context, builder: (_) => const BookingCreateDialog());

class BookingCreateDialog extends ConsumerStatefulWidget {
  const BookingCreateDialog({super.key});

  @override
  ConsumerState<BookingCreateDialog> createState() => _BookingCreateDialogState();
}

class _BookingCreateDialogState extends ConsumerState<BookingCreateDialog> with FormSubmit {
  final _players = TextEditingController();
  final _participants = TextEditingController();
  final _voucher = TextEditingController();
  final _notes = TextEditingController();
  UserDto? _client;
  int? _roomId;
  DateTime _date = today();
  int? _slotId;
  int? _promotionId;
  List<SlotDto>? _slots;
  List<PromotionDto> _promotions = const [];
  String? _optionsError;
  BookingQuoteDto? _quote;

  @override
  void dispose() {
    _players.dispose();
    _participants.dispose();
    _voucher.dispose();
    _notes.dispose();
    super.dispose();
  }

  RoomListItemDto? get _room {
    final rooms = ref.read(roomOptionsProvider).value ?? const <RoomListItemDto>[];
    return rooms.where((room) => room.id == _roomId).firstOrNull;
  }

  List<String> get _names => [
    for (final line in _participants.text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];

  Future<void> _loadOptions() async {
    final roomId = _roomId;
    final date = _date;
    setState(() {
      _slotId = null;
      _promotionId = null;
      _slots = null;
      _quote = null;
      _optionsError = null;
    });
    if (roomId == null) return;
    final api = ref.read(apiClientProvider);
    try {
      final (slots, promotions) = await waitBoth(
        api.schedules.slots(roomId: roomId, from: date, to: date),
        api.promotions.active(roomId: roomId, pageSize: 100),
      );
      if (!mounted || roomId != _roomId || date != _date) return;
      setState(() {
        _slots = [
          for (final slot in slots.items)
            if (slot.status == SlotStatus.available) slot,
        ];
        _promotions = promotions.items;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _optionsError = error.message);
    }
  }

  CreateBookingRequest _request() => CreateBookingRequest(
    scheduleId: _slotId!,
    clientId: _client?.id,
    playerCount: int.parse(_players.text.trim()),
    promotionId: _promotionId,
    voucherCode: optionalText(_voucher.text),
    notes: optionalText(_notes.text),
    participantNames: _names,
  );

  void _calculate() => submit(() async {
    final quote = await ref.read(apiClientProvider).bookings.quote(_request());
    if (mounted) setState(() => _quote = quote);
  });

  void _save() => submit(() async {
    final booking = await ref.read(apiClientProvider).bookings.create(_request());
    if (!mounted) return;
    Navigator.of(context).pop(booking);
    showSuccessSnackBar(
      context,
      'The booking for ${booking.clientName} in ${booking.roomName} on ${formatDate(booking.date)} '
      'at ${booking.startTime} was created.',
    );
  });

  String? _playersRule(String? value) {
    final room = _room;
    if (room == null) return Validators.intRange('Players', min: 1, max: 50)(value);
    return Validators.intRange('Players', min: room.minPlayers, max: room.maxPlayers)(value);
  }

  String? _participantsRule(String? _) {
    final players = int.tryParse(_players.text.trim());
    if (_names.any((name) => name.length > 200)) return 'Each participant name can have at most 200 characters.';
    return players != null && _names.length > players ? 'Enter at most $players names, one name on each line.' : null;
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'New booking',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      saveLabel: 'Create booking',
      width: 680,
      children: [
        _ClientField(
          validator: serverValidator<String>(
            'clientId',
            (_) => _client == null ? 'Select a client from the list. Type a part of the name or the email.' : null,
          ),
          onSelected: (client) => setState(() => _client = client),
        ),
        FieldRow(
          children: [
            RoomDropdown(
              value: _roomId,
              activeOnly: true,
              onChanged: (value) {
                _roomId = value;
                _loadOptions();
              },
              validator: Validators.selection<int>('a room'),
            ),
            DateFormField(
              label: 'Date',
              initialValue: _date,
              firstDate: today(),
              onChanged: (value) {
                _date = value;
                _loadOptions();
              },
            ),
          ],
        ),
        FieldRow(children: [_slotField(), _playersField()]),
        TextFormField(
          controller: _participants,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Participant names',
            helperText: 'Optional. Enter one name on each line, at most one name for each player.',
          ),
          validator: serverValidator('participantNames', _participantsRule),
        ),
        FieldRow(children: [_promotionField(), _voucherField()]),
        TextFormField(
          controller: _notes,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notes', helperText: 'Optional, at most 1000 characters.'),
          validator: serverValidator('notes', Validators.maxLength('Notes', 1000)),
        ),
        _PriceSummary(quote: _quote, onCalculate: saving ? null : _calculate),
      ],
    );
  }

  Widget _slotField() {
    final slots = _slots;
    final error = _optionsError;
    return DropdownButtonFormField<int>(
      key: ValueKey('slots-$_roomId-$_date-${slots?.length}'),
      initialValue: _slotId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Time slot',
        prefixIcon: const Icon(Icons.schedule),
        helperText: switch (slots) {
          _ when error != null => error,
          null => 'Select a room and a date first.',
          [] => 'This room has no free time slots on this date.',
          _ => null,
        },
      ),
      validator: serverValidator('scheduleId', Validators.selection<int>('a free time slot')),
      onChanged: (value) => setState(() {
        _slotId = value;
        _quote = null;
      }),
      items: [
        for (final slot in slots ?? const <SlotDto>[])
          DropdownMenuItem(value: slot.id, child: Text('${slot.startTime} to ${slot.endTime}')),
      ],
    );
  }

  Widget _playersField() {
    final room = _room;
    return TextFormField(
      controller: _players,
      onChanged: (_) => setState(() => _quote = null),
      decoration: InputDecoration(
        labelText: 'Players',
        prefixIcon: const Icon(Icons.groups_outlined),
        helperText: room == null ? 'A whole number.' : 'From ${room.minPlayers} to ${room.maxPlayers} players.',
      ),
      validator: serverValidator('playerCount', _playersRule),
    );
  }

  Widget _promotionField() {
    return DropdownButtonFormField<int>(
      key: ValueKey('promotions-$_roomId-${_promotions.length}'),
      initialValue: _promotionId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Promotion', prefixIcon: Icon(Icons.local_offer_outlined)),
      validator: serverValidator('promotionId'),
      onChanged: (value) => setState(() {
        _promotionId = value;
        _quote = null;
      }),
      items: [
        const DropdownMenuItem<int>(child: Text('No promotion')),
        for (final promotion in _promotions)
          DropdownMenuItem(
            value: promotion.id,
            child: Text(
              '${promotion.name} (${formatDiscount(promotion.discountValue, isPercentage: promotion.isPercentage)})',
            ),
          ),
      ],
    );
  }

  Widget _voucherField() {
    return TextFormField(
      controller: _voucher,
      onChanged: (_) => setState(() => _quote = null),
      decoration: const InputDecoration(
        labelText: 'Voucher code',
        prefixIcon: Icon(Icons.redeem_outlined),
        helperText: 'Optional. The code from a reward of the client.',
      ),
      validator: serverValidator('voucherCode', Validators.maxLength('Voucher code', 50)),
    );
  }
}

class _ClientField extends ConsumerStatefulWidget {
  const _ClientField({required this.validator, required this.onSelected});

  final FormFieldValidator<String> validator;
  final ValueChanged<UserDto?> onSelected;

  @override
  ConsumerState<_ClientField> createState() => _ClientFieldState();
}

class _ClientFieldState extends ConsumerState<_ClientField> {
  String? _searchError;

  Future<List<UserDto>> _search(TextEditingValue value) async {
    try {
      final page = await ref
          .read(apiClientProvider)
          .clients
          .list(isActive: true, search: optionalText(value.text), pageSize: 10);
      if (mounted && _searchError != null) setState(() => _searchError = null);
      return page.items;
    } on ApiException catch (error) {
      if (mounted) setState(() => _searchError = error.message);
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<UserDto>(
      displayStringForOption: (client) => '${client.fullName} (${client.email})',
      optionsBuilder: _search,
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (_) => widget.onSelected(null),
        decoration: InputDecoration(
          labelText: 'Client',
          prefixIcon: const Icon(Icons.person_search_outlined),
          helperText: _searchError ?? 'Type a part of the name or the email, then select the client.',
        ),
        validator: widget.validator,
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.quote, required this.onCalculate});

  final BookingQuoteDto? quote;
  final VoidCallback? onCalculate;

  @override
  Widget build(BuildContext context) {
    final value = quote;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Price', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onCalculate,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calculate the price'),
                ),
              ],
            ),
            if (value != null) ...[
              InfoRow(icon: Icons.receipt_long_outlined, label: 'Subtotal', value: formatMoney(value.subtotal)),
              InfoRow(
                icon: Icons.local_offer_outlined,
                label: 'Promotion discount',
                value: formatMoney(value.promotionDiscount),
              ),
              InfoRow(
                icon: Icons.redeem_outlined,
                label: 'Voucher discount',
                value: formatMoney(value.voucherDiscount),
              ),
              InfoRow(icon: Icons.payments_outlined, label: 'Total', value: formatMoney(value.totalPrice)),
            ],
          ],
        ),
      ),
    );
  }
}
