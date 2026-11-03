import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../widgets/empty_view.dart';
import 'room_providers.dart';

class SlotPicker extends ConsumerWidget {
  const SlotPicker({
    super.key,
    required this.roomId,
    required this.date,
    required this.selected,
    required this.onDate,
    required this.onSlot,
  });

  static const days = 14;

  final int roomId;
  final DateTime date;
  final SlotDto? selected;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<SlotDto> onSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(slotsProvider((roomId, date)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateStrip(selected: date, onSelected: onDate),
        const SizedBox(height: 12),
        const _Legend(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: slots.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorView(error: error, onRetry: () => ref.invalidate(slotsProvider((roomId, date)))),
            data: (items) => items.isEmpty
                ? const EmptyView(icon: Icons.event_busy_outlined, message: 'There are no time slots on this day.')
                : _SlotGrid(slots: items, selected: selected, onSlot: onSlot),
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends StatefulWidget {
  const _DateStrip({required this.selected, required this.onSelected});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  static const _chipExtent = 64.0;

  final _scroll = ScrollController();
  final _today = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: false));
  }

  @override
  void didUpdateWidget(_DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _reveal(animate: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int get _selectedIndex => _utcDay(widget.selected).difference(_utcDay(_today)).inDays;

  static DateTime _utcDay(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  bool get _inStrip => _selectedIndex < SlotPicker.days;

  void _reveal({required bool animate}) {
    if (!_scroll.hasClients || !_inStrip) return;
    final offset = (_selectedIndex * _chipExtent).clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(offset, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(offset);
    }
  }

  Future<void> _pick() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.selected,
      firstDate: _today,
      lastDate: DateUtils.addDaysToDate(_today, 90),
      helpText: 'Pick a date',
    );
    if (date != null) widget.onSelected(date);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: SlotPicker.days,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = DateUtils.addDaysToDate(_today, index);
                return _DateChip(date: date, selected: date == widget.selected, onTap: () => widget.onSelected(date));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Tooltip(
              message: 'Pick a date up to 90 days ahead',
              child: _DateChip(date: _inStrip ? null : widget.selected, selected: !_inStrip, onTap: _pick),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.selected, required this.onTap});

  final DateTime? date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    final small = theme.textTheme.labelSmall?.copyWith(color: foreground);
    final day = date;
    return Material(
      color: selected ? colors.primary : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? colors.primary : colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: day == null
                ? [
                    Icon(Icons.calendar_month_outlined, color: colors.primary),
                    const SizedBox(height: 4),
                    Text('More', style: small),
                  ]
                : [
                    Text(DateFormat('EEE').format(day), style: small),
                    Text('${day.day}', style: theme.textTheme.titleMedium?.copyWith(color: foreground)),
                    Text(DateFormat('MMM').format(day), style: small),
                  ],
          ),
        ),
      ),
    );
  }
}

enum _SlotLook { available, selected, booked, closed }

({Color background, Color foreground, Color border}) _colors(ColorScheme colors, _SlotLook look) => switch (look) {
  _SlotLook.available => (
    background: colors.primaryContainer,
    foreground: colors.onPrimaryContainer,
    border: colors.primary,
  ),
  _SlotLook.selected => (background: colors.primary, foreground: colors.onPrimary, border: colors.primary),
  _SlotLook.booked => (
    background: colors.errorContainer,
    foreground: colors.onErrorContainer,
    border: colors.errorContainer,
  ),
  _SlotLook.closed => (
    background: colors.surfaceContainerHighest,
    foreground: colors.outline,
    border: colors.surfaceContainerHighest,
  ),
};

_SlotLook _look(SlotDto slot, SlotDto? selected) => switch (slot.status) {
  SlotStatus.available => slot.id == selected?.id ? _SlotLook.selected : _SlotLook.available,
  SlotStatus.booked => _SlotLook.booked,
  SlotStatus.past || SlotStatus.blocked => _SlotLook.closed,
};

class _Legend extends StatelessWidget {
  const _Legend();

  static const _items = {
    _SlotLook.available: 'Available',
    _SlotLook.selected: 'Selected',
    _SlotLook.booked: 'Booked',
    _SlotLook.closed: 'Past or closed',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          for (final MapEntry(key: look, value: label) in _items.entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _colors(colors, look).background,
                    border: Border.all(color: _colors(colors, look).border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({required this.slots, required this.selected, required this.onSlot});

  final List<SlotDto> slots;
  final SlotDto? selected;
  final ValueChanged<SlotDto> onSlot;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2,
      children: [
        for (final slot in slots)
          _SlotTile(
            slot: slot,
            look: _look(slot, selected),
            onTap: slot.status == SlotStatus.available ? () => onSlot(slot) : null,
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.look, required this.onTap});

  final SlotDto slot;
  final _SlotLook look;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _colors(theme.colorScheme, look);
    return Material(
      color: palette.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slot.startTime,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: palette.foreground,
                  decoration: look == _SlotLook.booked ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                look == _SlotLook.selected ? 'Selected' : slot.status.value,
                style: theme.textTheme.labelSmall?.copyWith(color: palette.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
