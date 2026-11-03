import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';

extension ReferenceTableLabels on ReferenceTable {
  String get title => switch (this) {
    ReferenceTable.themes => 'Themes',
    ReferenceTable.countries => 'Countries',
    ReferenceTable.cities => 'Cities',
    ReferenceTable.difficultyLevels => 'Difficulty levels',
    ReferenceTable.bookingStatuses => 'Booking statuses',
    ReferenceTable.promotionTypes => 'Promotion types',
    ReferenceTable.rewardTypes => 'Reward types',
  };

  String get singular => switch (this) {
    ReferenceTable.themes => 'theme',
    ReferenceTable.countries => 'country',
    ReferenceTable.cities => 'city',
    ReferenceTable.difficultyLevels => 'difficulty level',
    ReferenceTable.bookingStatuses => 'booking status',
    ReferenceTable.promotionTypes => 'promotion type',
    ReferenceTable.rewardTypes => 'reward type',
  };

  bool get isDiscountType => this == ReferenceTable.promotionTypes || this == ReferenceTable.rewardTypes;
}

Future<ReferenceDto?> showReferenceForm(BuildContext context, ReferenceTable table, [ReferenceDto? item]) =>
    showDialog<ReferenceDto>(
      context: context,
      builder: (_) => ReferenceFormDialog(table: table, item: item),
    );

class ReferenceFormDialog extends ConsumerStatefulWidget {
  const ReferenceFormDialog({super.key, required this.table, this.item});

  final ReferenceTable table;
  final ReferenceDto? item;

  @override
  ConsumerState<ReferenceFormDialog> createState() => _ReferenceFormDialogState();
}

class _ReferenceFormDialogState extends ConsumerState<ReferenceFormDialog> with FormSubmit {
  late final _name = TextEditingController(text: widget.item?.name);
  late final _value = TextEditingController(
    text: switch (widget.item) {
      DifficultyLevelDto(:final value) => '$value',
      _ => '',
    },
  );
  late int? _countryId = switch (widget.item) {
    CityDto(:final countryId) => countryId,
    _ => null,
  };
  late bool _isPercentage = switch (widget.item) {
    DiscountTypeDto(:final isPercentage) => isPercentage,
    _ => false,
  };

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  ReferenceRequest _request() {
    final name = _name.text.trim();
    return switch (widget.table) {
      ReferenceTable.cities => CityRequest(name: name, countryId: _countryId!),
      ReferenceTable.difficultyLevels => DifficultyLevelRequest(name: name, value: int.parse(_value.text.trim())),
      ReferenceTable.promotionTypes ||
      ReferenceTable.rewardTypes => DiscountTypeRequest(name: name, isPercentage: _isPercentage),
      _ => ReferenceRequest(name: name),
    };
  }

  void _save() => submit(() async {
    final api = ref.read(apiClientProvider).references;
    final item = widget.item;
    final saved = item == null
        ? await api.create(widget.table, _request())
        : await api.update(widget.table, item.id, _request());
    ref.invalidate(referenceProvider(widget.table));
    if (!mounted) return;
    Navigator.of(context).pop(saved);
    final action = item == null ? 'created' : 'saved';
    showSuccessSnackBar(context, 'The ${widget.table.singular} ${saved.name} was $action.');
  });

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    return FormDialog(
      title: widget.item == null ? 'New ${table.singular}' : 'Edit ${table.singular}',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      width: 440,
      children: [
        TextFormField(
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name', helperText: 'At most 100 characters.'),
          validator: serverValidator(
            'name',
            Validators.combine([Validators.required('Name'), Validators.maxLength('Name', 100)]),
          ),
        ),
        if (table == ReferenceTable.cities)
          ReferenceDropdown(
            table: ReferenceTable.countries,
            label: 'Country',
            value: _countryId,
            canAdd: true,
            onChanged: (value) => setState(() => _countryId = value),
            validator: serverValidator('countryId', Validators.selection<int>('a country')),
          ),
        if (table == ReferenceTable.difficultyLevels)
          TextFormField(
            controller: _value,
            decoration: const InputDecoration(
              labelText: 'Difficulty value',
              helperText: 'A whole number from 1 (easiest) to 10 (hardest).',
            ),
            validator: serverValidator('value', Validators.intRange('Difficulty value', min: 1, max: 10)),
          ),
        if (table.isDiscountType)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Percentage discount'),
            subtitle: const Text('Turn off for a fixed amount in KM.'),
            value: _isPercentage,
            onChanged: (value) => setState(() => _isPercentage = value),
          ),
      ],
    );
  }
}
