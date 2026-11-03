import 'package:escapehub_core/escapehub_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';

typedef PickedImage = ({Uint8List bytes, String name});

const _maxImageBytes = 5 * 1024 * 1024;

Future<RoomDto?> showRoomForm(BuildContext context, [RoomDto? room]) => showDialog<RoomDto>(
  context: context,
  builder: (_) => RoomFormDialog(room: room),
);

class RoomFormDialog extends ConsumerStatefulWidget {
  const RoomFormDialog({super.key, this.room});

  final RoomDto? room;

  @override
  ConsumerState<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends ConsumerState<RoomFormDialog> with FormSubmit {
  late final _name = TextEditingController(text: widget.room?.name);
  late final _shortDescription = TextEditingController(text: widget.room?.shortDescription);
  late final _longDescription = TextEditingController(text: widget.room?.longDescription);
  late final _minPlayers = TextEditingController(text: '${widget.room?.minPlayers ?? 2}');
  late final _maxPlayers = TextEditingController(text: '${widget.room?.maxPlayers ?? 6}');
  late final _duration = TextEditingController(text: '${widget.room?.durationMinutes ?? 60}');
  late final _pricePerPerson = TextEditingController(text: formatNumber(widget.room?.pricePerPerson ?? 0));
  late final _pricePerBooking = TextEditingController(text: formatNumber(widget.room?.pricePerBooking ?? 0));
  late final _age = TextEditingController(text: widget.room?.ageRecommendation);
  late int? _themeId = widget.room?.themeId;
  late int? _difficultyId = widget.room?.difficultyLevelId;
  late int? _cityId = widget.room?.cityId;
  late int? _managerId = widget.room?.managerId;
  late bool _isActive = widget.room?.isActive ?? true;
  late String? _imageUrl = widget.room?.imageUrl;
  PickedImage? _image;
  String? _imageError;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _shortDescription,
      _longDescription,
      _minPlayers,
      _maxPlayers,
      _duration,
      _pricePerPerson,
      _pricePerBooking,
      _age,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  SaveRoomRequest _request() => SaveRoomRequest(
    name: _name.text.trim(),
    shortDescription: _shortDescription.text.trim(),
    longDescription: _longDescription.text.trim(),
    themeId: _themeId!,
    difficultyLevelId: _difficultyId!,
    minPlayers: int.parse(_minPlayers.text.trim()),
    maxPlayers: int.parse(_maxPlayers.text.trim()),
    durationMinutes: int.parse(_duration.text.trim()),
    pricePerPerson: parseDecimal(_pricePerPerson.text)!,
    pricePerBooking: parseDecimal(_pricePerBooking.text)!,
    isActive: _isActive,
    ageRecommendation: optionalText(_age.text),
    cityId: _cityId,
    managerId: _managerId,
  );

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp']);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageError = bytes.length > _maxImageBytes ? 'The image is larger than 5 MB. Select a smaller image.' : null;
      _image = _imageError == null ? (bytes: bytes, name: file.name) : null;
    });
  }

  void _removeImage() => setState(() {
    _image = null;
    _imageUrl = null;
  });

  Future<String?> _saveImage(int roomId) async {
    final files = ref.read(apiClientProvider).files;
    final image = _image;
    try {
      if (image != null) {
        await files.uploadRoomImage(roomId, image.bytes, image.name);
      } else if (_imageUrl == null && widget.room?.imageUrl != null) {
        await files.removeRoomImage(roomId);
      }
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  void _save() => submit(() async {
    final api = ref.read(apiClientProvider).rooms;
    final room = widget.room;
    final saved = room == null ? await api.create(_request()) : await api.update(room.id, _request());
    final imageError = await _saveImage(saved.id);
    ref.invalidate(roomOptionsProvider);
    if (!mounted) return;
    Navigator.of(context).pop(saved);
    if (imageError != null) {
      showErrorSnackBar(context, 'The room ${saved.name} was saved, but the image was not changed. $imageError');
    } else {
      showSuccessSnackBar(context, 'The room ${saved.name} was ${room == null ? 'created' : 'saved'}.');
    }
  });

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.room == null ? 'New room' : 'Edit room',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      width: 940,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _fields()),
            const SizedBox(width: 24),
            SizedBox(
              width: 300,
              child: _ImagePanel(
                image: _image,
                imageUrl: _imageUrl,
                label: _name.text,
                error: _imageError,
                onPick: _pickImage,
                onRemove: _image == null && _imageUrl == null ? null : _removeImage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fields() {
    final isAdministrator = ref.watch(currentUserProvider.select((user) => user?.isAdministrator ?? false));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _descriptionFields(),
        const SizedBox(height: 16),
        FieldRow(
          children: [
            ReferenceDropdown(
              table: ReferenceTable.themes,
              label: 'Theme',
              value: _themeId,
              canAdd: isAdministrator,
              onChanged: (value) => setState(() => _themeId = value),
              validator: serverValidator('themeId', Validators.selection<int>('a theme')),
            ),
            ReferenceDropdown(
              table: ReferenceTable.difficultyLevels,
              label: 'Difficulty level',
              value: _difficultyId,
              canAdd: isAdministrator,
              onChanged: (value) => setState(() => _difficultyId = value),
              validator: serverValidator('difficultyLevelId', Validators.selection<int>('a difficulty level')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FieldRow(
          children: [
            ReferenceDropdown(
              table: ReferenceTable.cities,
              label: 'City',
              value: _cityId,
              emptyLabel: 'No city',
              canAdd: isAdministrator,
              onChanged: (value) => setState(() => _cityId = value),
              validator: serverValidator('cityId'),
            ),
            if (isAdministrator) _managerField(),
          ],
        ),
        if (!isAdministrator) ...[
          const SizedBox(height: 8),
          Text(
            'Only an administrator can add themes, difficulty levels and cities. Ask an administrator to add them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        _capacityFields(),
        const SizedBox(height: 16),
        _priceFields(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active'),
          subtitle: const Text('Clients can see and book an active room.'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }

  Widget _descriptionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _name,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Name', helperText: 'At most 200 characters.'),
          validator: serverValidator(
            'name',
            Validators.combine([Validators.required('Name'), Validators.maxLength('Name', 200)]),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _shortDescription,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Short description', helperText: 'At most 500 characters.'),
          validator: serverValidator(
            'shortDescription',
            Validators.combine([
              Validators.required('Short description'),
              Validators.maxLength('Short description', 500),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _longDescription,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Long description', helperText: 'At most 2000 characters.'),
          validator: serverValidator('longDescription', Validators.maxLength('Long description', 2000)),
        ),
      ],
    );
  }

  Widget _managerField() {
    final managers = ref.watch(managerOptionsProvider).value ?? const <UserDto>[];
    final room = widget.room;
    final current = room?.managerId;
    final missing = current != null && managers.every((manager) => manager.id != current);
    return DropdownButtonFormField<int>(
      initialValue: _managerId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Room manager'),
      validator: serverValidator('managerId'),
      onChanged: (value) => setState(() => _managerId = value),
      items: [
        const DropdownMenuItem<int>(child: Text('No manager')),
        if (missing) DropdownMenuItem(value: current, child: Text(room?.managerName ?? '')),
        for (final manager in managers) DropdownMenuItem(value: manager.id, child: Text(manager.fullName)),
      ],
    );
  }

  Widget _capacityFields() {
    return FieldRow(
      children: [
        TextFormField(
          controller: _minPlayers,
          decoration: const InputDecoration(labelText: 'Minimum players', prefixIcon: Icon(Icons.group_outlined)),
          validator: serverValidator('minPlayers', Validators.intRange('Minimum players', min: 1, max: 50)),
        ),
        TextFormField(
          controller: _maxPlayers,
          decoration: const InputDecoration(labelText: 'Maximum players', prefixIcon: Icon(Icons.groups_outlined)),
          validator: serverValidator(
            'maxPlayers',
            Validators.combine([Validators.intRange('Maximum players', min: 1, max: 50), _notBelowMinimum]),
          ),
        ),
        TextFormField(
          controller: _duration,
          decoration: const InputDecoration(labelText: 'Duration in minutes', prefixIcon: Icon(Icons.timer_outlined)),
          validator: serverValidator('durationMinutes', Validators.intRange('Duration', min: 15, max: 240)),
        ),
      ],
    );
  }

  String? _notBelowMinimum(String? value) {
    final minimum = int.tryParse(_minPlayers.text.trim());
    final maximum = int.tryParse(value?.trim() ?? '');
    return minimum != null && maximum != null && maximum < minimum
        ? 'Maximum players must be equal to or more than minimum players ($minimum).'
        : null;
  }

  Widget _priceFields() {
    return FieldRow(
      children: [
        TextFormField(
          controller: _pricePerPerson,
          decoration: const InputDecoration(
            labelText: 'Price per person (KM)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          validator: serverValidator('pricePerPerson', Validators.decimalRange('Price per person', min: 0, max: 1000)),
        ),
        TextFormField(
          controller: _pricePerBooking,
          decoration: const InputDecoration(
            labelText: 'Price per booking (KM)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          validator: serverValidator(
            'pricePerBooking',
            Validators.decimalRange('Price per booking', min: 0, max: 10000),
          ),
        ),
        TextFormField(
          controller: _age,
          decoration: const InputDecoration(labelText: 'Age recommendation', helperText: 'Optional, for example 12+.'),
          validator: serverValidator('ageRecommendation', Validators.maxLength('Age recommendation', 100)),
        ),
      ],
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.image,
    required this.imageUrl,
    required this.label,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  final PickedImage? image;
  final String? imageUrl;
  final String label;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = image;
    final message = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Image', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: picked == null
              ? ApiImage(path: imageUrl, label: label, borderRadius: BorderRadius.circular(8))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(picked.bytes, fit: BoxFit.cover),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          picked == null ? 'JPEG, PNG or WebP, at most 5 MB.' : 'New image: ${picked.name}',
          style: theme.textTheme.bodySmall,
        ),
        if (message != null) Text(message, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Choose'),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: onRemove == null ? 'The room has no image.' : 'Remove the image',
              child: TextButton(onPressed: onRemove, child: const Text('Remove')),
            ),
          ],
        ),
      ],
    );
  }
}
