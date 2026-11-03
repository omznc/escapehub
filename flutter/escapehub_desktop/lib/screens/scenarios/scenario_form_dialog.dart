import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/room_dropdown.dart';

Future<RoomScenarioDto?> showScenarioForm(BuildContext context, [RoomScenarioDto? scenario]) =>
    showDialog<RoomScenarioDto>(
      context: context,
      builder: (_) => ScenarioFormDialog(scenario: scenario),
    );

class ScenarioFormDialog extends ConsumerStatefulWidget {
  const ScenarioFormDialog({super.key, this.scenario});

  final RoomScenarioDto? scenario;

  @override
  ConsumerState<ScenarioFormDialog> createState() => _ScenarioFormDialogState();
}

class _ScenarioFormDialogState extends ConsumerState<ScenarioFormDialog> with FormSubmit {
  late final _name = TextEditingController(text: widget.scenario?.name);
  late final _story = TextEditingController(text: widget.scenario?.story);
  late final _hintPolicy = TextEditingController(text: widget.scenario?.hintPolicy);
  late int? _roomId = widget.scenario?.roomId;
  late int? _difficultyId = widget.scenario?.difficultyOverrideId;
  late bool _isActive = widget.scenario?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _story.dispose();
    _hintPolicy.dispose();
    super.dispose();
  }

  SaveRoomScenarioRequest _request() => SaveRoomScenarioRequest(
    roomId: _roomId!,
    name: _name.text.trim(),
    story: _story.text.trim(),
    difficultyOverrideId: _difficultyId,
    hintPolicy: optionalText(_hintPolicy.text),
    isActive: _isActive,
  );

  void _save() => submit(() async {
    final api = ref.read(apiClientProvider).scenarios;
    final scenario = widget.scenario;
    final saved = scenario == null ? await api.create(_request()) : await api.update(scenario.id, _request());
    if (!mounted) return;
    Navigator.of(context).pop(saved);
    showSuccessSnackBar(context, 'The scenario ${saved.name} was ${scenario == null ? 'created' : 'saved'}.');
  });

  @override
  Widget build(BuildContext context) {
    final isAdministrator = ref.watch(currentUserProvider.select((user) => user?.isAdministrator ?? false));
    return FormDialog(
      title: widget.scenario == null ? 'New scenario' : 'Edit scenario',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      width: 560,
      children: [
        RoomDropdown(
          value: _roomId,
          onChanged: (value) => setState(() => _roomId = value),
          validator: serverValidator('roomId', Validators.selection<int>('a room')),
        ),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name', helperText: 'At most 200 characters.'),
          validator: serverValidator(
            'name',
            Validators.combine([Validators.required('Name'), Validators.maxLength('Name', 200)]),
          ),
        ),
        TextFormField(
          controller: _story,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Story', helperText: 'At most 2000 characters.'),
          validator: serverValidator(
            'story',
            Validators.combine([Validators.required('Story'), Validators.maxLength('Story', 2000)]),
          ),
        ),
        ReferenceDropdown(
          table: ReferenceTable.difficultyLevels,
          label: 'Difficulty',
          value: _difficultyId,
          emptyLabel: 'Same as the room',
          canAdd: isAdministrator,
          onChanged: (value) => setState(() => _difficultyId = value),
          validator: serverValidator('difficultyOverrideId'),
        ),
        TextFormField(
          controller: _hintPolicy,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Hint policy',
            helperText: 'Optional, at most 500 characters. For example: three free hints.',
          ),
          validator: serverValidator('hintPolicy', Validators.maxLength('Hint policy', 500)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active'),
          subtitle: const Text('Clients see only the active scenarios of a room.'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }
}
