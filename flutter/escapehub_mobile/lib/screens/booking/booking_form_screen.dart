import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../formatting.dart';
import '../../providers.dart';
import '../../widgets/busy_button.dart';
import '../../widgets/form_message.dart';
import '../../widgets/section_header.dart';
import 'booking_options.dart';
import 'discount_fields.dart';
import 'quote_summary.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({super.key, required this.room, required this.slot});

  final RoomDto room;
  final SlotDto slot;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _serverErrors = ServerErrors();
  late final List<TextEditingController> _names = [
    for (var index = 0; index < widget.room.maxPlayers; index++) TextEditingController(),
  ];
  late int _players = widget.room.minPlayers;
  int? _promotionId;
  int? _redemptionId;
  BookingQuoteDto? _quote;
  String? _quoteError;
  int _quoteRequest = 0;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _names.first.text = ref.read(currentUserProvider)?.fullName ?? '';
    _refreshQuote();
  }

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  CreateBookingRequest _request() => CreateBookingRequest(
    scheduleId: widget.slot.id,
    playerCount: _players,
    promotionId: _promotionId,
    redemptionId: _redemptionId,
    participantNames: [
      for (final controller in _names.take(_players))
        if (controller.text.trim().isNotEmpty) controller.text.trim(),
    ],
  );

  Future<void> _refreshQuote() async {
    final request = ++_quoteRequest;
    setState(() => _quoteError = null);
    try {
      final quote = await ref.read(apiClientProvider).bookings.quote(_request());
      if (mounted && request == _quoteRequest) setState(() => _quote = quote);
    } on ApiException catch (error) {
      if (!mounted || request != _quoteRequest) return;
      setState(() {
        _quote = null;
        _quoteError = error.message;
      });
    }
  }

  void _change(VoidCallback update) {
    setState(() {
      update();
      _quote = null;
    });
    _serverErrors.clear();
    _refreshQuote();
  }

  Future<bool> _confirm(BookingQuoteDto quote) => showConfirmDialog(
    context,
    title: 'Confirm booking',
    message:
        'Book ${widget.room.name} on ${formatDay(widget.slot.date)} at ${widget.slot.startTime} '
        'for ${formatPlayerCount(_players)}? The total price is ${formatMoney(quote.totalPrice)}.',
    confirmLabel: 'Book now',
  );

  void _finish(BookingDto booking) {
    final messenger = ScaffoldMessenger.of(context);
    ref.read(newBookingProvider.notifier).show(booking);
    ref.read(shellTabProvider.notifier).select(ShellTab.bookings);
    ref.bookingsChanged();
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Your booking for ${booking.roomName} on ${formatDay(booking.date)} at ${booking.startTime} '
          'was created. The status is ${booking.statusName}.',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _serverErrors.clear();
    setState(() => _message = null);
    final quote = _quote;
    if (!_form.currentState!.validate() || quote == null) return;
    if (!await _confirm(quote) || !mounted) return;
    setState(() => _busy = true);
    try {
      final booking = await ref.read(apiClientProvider).bookings.create(_request());
      if (mounted) _finish(booking);
    } on ApiException catch (error) {
      final message = _serverErrors.apply(error);
      if (!mounted) return;
      _form.currentState!.validate();
      setState(() => _message = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(bookingOptionsProvider(widget.room.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Book a session')),
      body: Form(
        key: _form,
        canPop: !_busy,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _SlotHeader(room: widget.room, slot: widget.slot),
            const SectionHeader('Players'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _playersField()),
            ..._nameFields(),
            const SectionHeader('Discounts'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DiscountFields(
                options: options,
                promotionId: _promotionId,
                redemptionId: _redemptionId,
                serverErrors: _serverErrors,
                onPromotion: (id) => _change(() => _promotionId = id),
                onRedemption: (id) => _change(() => _redemptionId = id),
              ),
            ),
            const SectionHeader('Price'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuoteSummary(quote: _quote, error: _quoteError, players: _players),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormMessage(_message),
              BusyButton(
                label: 'Confirm booking',
                icon: Icons.check,
                busy: _busy,
                onPressed: _quote == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playersField() {
    final room = widget.room;
    return DropdownButtonFormField<int>(
      initialValue: _players,
      decoration: InputDecoration(
        labelText: 'Party size',
        prefixIcon: const Icon(Icons.group_outlined),
        helperText: 'This room allows ${formatPlayers(room.minPlayers, room.maxPlayers)}.',
      ),
      items: [
        for (var size = room.minPlayers; size <= room.maxPlayers; size++)
          DropdownMenuItem(value: size, child: Text(formatPlayerCount(size))),
      ],
      validator: _serverErrors.validator<int>('playerCount'),
      onChanged: (size) => _change(() => _players = size ?? _players),
    );
  }

  List<Widget> _nameFields() => [
    for (var index = 0; index < _players; index++)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextFormField(
          controller: _names[index],
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Player ${index + 1} name (optional)',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: index == 0
              ? _serverErrors.validator('participantNames', Validators.maxLength('Player 1 name', 200))
              : Validators.maxLength('Player ${index + 1} name', 200),
        ),
      ),
  ];
}

class _SlotHeader extends StatelessWidget {
  const _SlotHeader({required this.room, required this.slot});

  final RoomDto room;
  final SlotDto slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ApiImage(
                path: room.imageUrl,
                label: room.name,
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(formatDay(slot.date)),
                    Text(formatTimeRange(slot.startTime, slot.endTime)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
