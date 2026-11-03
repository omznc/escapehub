import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format.dart';
import '../screens/reference/reference_form_dialog.dart';

class DateFormField extends FormField<DateTime> {
  DateFormField({
    super.key,
    required String label,
    required ValueChanged<DateTime> onChanged,
    super.initialValue,
    super.validator,
    DateTime? firstDate,
    DateTime? lastDate,
  }) : super(
         builder: (field) => _PickerInput(
           label: label,
           icon: Icons.calendar_today_outlined,
           text: field.value == null ? 'Select a date' : formatDate(field.value!),
           errorText: field.errorText,
           onTap: () async {
             final first = firstDate ?? DateTime(2020);
             final initial = field.value ?? today();
             final picked = await showDatePicker(
               context: field.context,
               initialDate: initial.isBefore(first) ? first : initial,
               firstDate: first,
               lastDate: lastDate ?? DateTime(2100),
             );
             if (picked == null) return;
             field.didChange(picked);
             onChanged(picked);
           },
         ),
       );
}

class TimeFormField extends FormField<String> {
  TimeFormField({
    super.key,
    required String label,
    required ValueChanged<String> onChanged,
    super.initialValue,
    super.validator,
  }) : super(
         builder: (field) => _PickerInput(
           label: label,
           icon: Icons.schedule,
           text: field.value ?? 'Select a time',
           errorText: field.errorText,
           onTap: () async {
             final picked = await showTimePicker(
               context: field.context,
               initialTime: _parseTime(field.value),
               builder: (context, child) =>
                   MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
             );
             if (picked == null) return;
             final text = formatTime(picked.hour, picked.minute);
             field.didChange(text);
             onChanged(text);
           },
         ),
       );

  static TimeOfDay _parseTime(String? value) {
    final parts = (value ?? '18:00').split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class _PickerInput extends StatelessWidget {
  const _PickerInput({
    required this.label,
    required this.icon,
    required this.text,
    required this.errorText,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String text;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), errorText: errorText),
        child: Text(text),
      ),
    );
  }
}

class ReferenceDropdown extends ConsumerWidget {
  const ReferenceDropdown({
    super.key,
    required this.table,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.emptyLabel,
    this.canAdd = false,
  });

  final ReferenceTable table;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final FormFieldValidator<int>? validator;
  final String? emptyLabel;
  final bool canAdd;

  Future<void> _add(BuildContext context) async {
    final created = await showReferenceForm(context, table);
    if (created != null && context.mounted) onChanged(created.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(referenceProvider(table));
    final items = options.value ?? const <ReferenceDto>[];
    final empty = emptyLabel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey('${table.name}-$value-${items.length}'),
            initialValue: items.any((item) => item.id == value) ? value : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: label, helperText: listError(options.error)),
            validator: validator,
            onChanged: onChanged,
            items: [
              if (empty != null) DropdownMenuItem<int>(child: Text(empty)),
              for (final item in items) DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Tooltip(
            message: canAdd ? 'Add a new ${table.singular}' : 'Only an administrator can add a new ${table.singular}.',
            child: IconButton(onPressed: canAdd ? () => _add(context) : null, icon: const Icon(Icons.add)),
          ),
        ),
      ],
    );
  }
}

String? listError(Object? error) => error == null ? null : 'The list could not be loaded. $error';

class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ],
    );
  }
}
