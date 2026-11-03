import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';

Future<PromotionDto?> showPromotionForm(BuildContext context, [PromotionDto? promotion]) => showDialog<PromotionDto>(
  context: context,
  builder: (_) => PromotionFormDialog(promotion: promotion),
);

class PromotionFormDialog extends ConsumerStatefulWidget {
  const PromotionFormDialog({super.key, this.promotion});

  final PromotionDto? promotion;

  @override
  ConsumerState<PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends ConsumerState<PromotionFormDialog> with FormSubmit {
  late final _name = TextEditingController(text: widget.promotion?.name);
  late final _description = TextEditingController(text: widget.promotion?.description);
  late final _discount = TextEditingController(
    text: widget.promotion == null ? '' : formatNumber(widget.promotion!.discountValue),
  );
  late int? _typeId = widget.promotion?.promotionTypeId;
  late DateTime? _startDate = widget.promotion?.startDate ?? today();
  late DateTime? _endDate = widget.promotion?.endDate;
  late bool _isActive = widget.promotion?.isActive ?? true;
  late final Set<int> _roomIds = {...?widget.promotion?.rooms.map((room) => room.id)};

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _discount.dispose();
    super.dispose();
  }

  bool get _isPercentage {
    final types = ref.watch(referenceProvider(ReferenceTable.promotionTypes)).value ?? const <ReferenceDto>[];
    return types.whereType<DiscountTypeDto>().any((type) => type.id == _typeId && type.isPercentage);
  }

  SavePromotionRequest _request() => SavePromotionRequest(
    name: _name.text.trim(),
    description: _description.text.trim(),
    promotionTypeId: _typeId!,
    discountValue: parseDecimal(_discount.text)!,
    startDate: _startDate!,
    endDate: _endDate!,
    isActive: _isActive,
    roomIds: _roomIds.toList(),
  );

  void _save() => submit(() async {
    final api = ref.read(apiClientProvider).promotions;
    final promotion = widget.promotion;
    final saved = promotion == null ? await api.create(_request()) : await api.update(promotion.id, _request());
    if (!mounted) return;
    Navigator.of(context).pop(saved);
    showSuccessSnackBar(context, 'The promotion ${saved.name} was ${promotion == null ? 'created' : 'saved'}.');
  });

  String? _endRule(DateTime? value) {
    if (value == null) return 'Select an end date.';
    final start = _startDate;
    return start != null && value.isBefore(start) ? 'The end date must be on or after the start date.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final isAdministrator = ref.watch(currentUserProvider.select((user) => user?.isAdministrator ?? false));
    final isPercentage = _isPercentage;
    return FormDialog(
      title: widget.promotion == null ? 'New promotion' : 'Edit promotion',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      width: 640,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name', helperText: 'At most 200 characters.'),
          validator: serverValidator(
            'name',
            Validators.combine([Validators.required('Name'), Validators.maxLength('Name', 200)]),
          ),
        ),
        TextFormField(
          controller: _description,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Description', helperText: 'Optional, at most 1000 characters.'),
          validator: serverValidator('description', Validators.maxLength('Description', 1000)),
        ),
        FieldRow(
          children: [
            ReferenceDropdown(
              table: ReferenceTable.promotionTypes,
              label: 'Promotion type',
              value: _typeId,
              canAdd: isAdministrator,
              onChanged: (value) => setState(() => _typeId = value),
              validator: serverValidator('promotionTypeId', Validators.selection<int>('a promotion type')),
            ),
            TextFormField(
              controller: _discount,
              decoration: InputDecoration(
                labelText: isPercentage ? 'Discount (%)' : 'Discount (KM)',
                prefixIcon: const Icon(Icons.sell_outlined),
                helperText: isPercentage
                    ? 'From 0.01 to 100, for example 15.'
                    : 'From 0.01 to 10000, for example 20.50.',
              ),
              validator: serverValidator(
                'discountValue',
                Validators.decimalRange('Discount', min: 0.01, max: isPercentage ? 100 : 10000),
              ),
            ),
          ],
        ),
        FieldRow(
          children: [
            DateFormField(
              label: 'Start date',
              initialValue: _startDate,
              onChanged: (value) => setState(() => _startDate = value),
              validator: serverValidator('startDate', Validators.selection<DateTime>('a start date')),
            ),
            DateFormField(
              label: 'End date',
              initialValue: _endDate,
              onChanged: (value) => setState(() => _endDate = value),
              validator: serverValidator('endDate', _endRule),
            ),
          ],
        ),
        _RoomChips(
          selected: _roomIds,
          required: !isAdministrator,
          onChanged: (roomId, selected) => setState(() => selected ? _roomIds.add(roomId) : _roomIds.remove(roomId)),
          validator: serverValidator('roomIds'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active'),
          subtitle: const Text('Clients can use an active promotion between the start date and the end date.'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }
}

class _RoomChips extends ConsumerWidget {
  const _RoomChips({required this.selected, required this.required, required this.onChanged, required this.validator});

  final Set<int> selected;
  final bool required;
  final void Function(int roomId, bool selected) onChanged;
  final FormFieldValidator<Set<int>> validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomOptionsProvider).value ?? const <RoomListItemDto>[];
    return FormField<Set<int>>(
      initialValue: selected,
      validator: (value) => required && selected.isEmpty ? 'Select at least one of your rooms.' : validator(selected),
      builder: (field) => InputDecorator(
        decoration: InputDecoration(
          labelText: 'Rooms',
          helperText: required
              ? 'Select one or more of your rooms.'
              : 'Select no room to apply the promotion to all rooms.',
          errorText: field.errorText,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final room in rooms)
              if (room.isActive || selected.contains(room.id))
                FilterChip(
                  label: Text(room.name),
                  selected: selected.contains(room.id),
                  onSelected: (value) => onChanged(room.id, value),
                ),
          ],
        ),
      ),
    );
  }
}
