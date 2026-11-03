import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/form_fields.dart';

Future<LoyaltyRewardDto?> showRewardForm(BuildContext context, [LoyaltyRewardDto? reward]) =>
    showDialog<LoyaltyRewardDto>(
      context: context,
      builder: (_) => RewardFormDialog(reward: reward),
    );

class RewardFormDialog extends ConsumerStatefulWidget {
  const RewardFormDialog({super.key, this.reward});

  final LoyaltyRewardDto? reward;

  @override
  ConsumerState<RewardFormDialog> createState() => _RewardFormDialogState();
}

class _RewardFormDialogState extends ConsumerState<RewardFormDialog> with FormSubmit {
  late final _name = TextEditingController(text: widget.reward?.name);
  late final _description = TextEditingController(text: widget.reward?.description);
  late final _points = TextEditingController(text: widget.reward == null ? '' : '${widget.reward!.pointsCost}');
  late final _value = TextEditingController(text: widget.reward == null ? '' : formatNumber(widget.reward!.value));
  late int? _typeId = widget.reward?.rewardTypeId;
  late bool _isActive = widget.reward?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _points.dispose();
    _value.dispose();
    super.dispose();
  }

  bool get _isPercentage {
    final types = ref.watch(referenceProvider(ReferenceTable.rewardTypes)).value ?? const <ReferenceDto>[];
    return types.whereType<DiscountTypeDto>().any((type) => type.id == _typeId && type.isPercentage);
  }

  SaveLoyaltyRewardRequest _request() => SaveLoyaltyRewardRequest(
    name: _name.text.trim(),
    description: _description.text.trim(),
    pointsCost: int.parse(_points.text.trim()),
    rewardTypeId: _typeId!,
    value: parseDecimal(_value.text)!,
    isActive: _isActive,
  );

  void _save() => submit(() async {
    final api = ref.read(apiClientProvider).loyalty;
    final reward = widget.reward;
    final saved = reward == null ? await api.createReward(_request()) : await api.updateReward(reward.id, _request());
    if (!mounted) return;
    Navigator.of(context).pop(saved);
    showSuccessSnackBar(context, 'The reward ${saved.name} was ${reward == null ? 'created' : 'saved'}.');
  });

  @override
  Widget build(BuildContext context) {
    final isPercentage = _isPercentage;
    return FormDialog(
      title: widget.reward == null ? 'New reward' : 'Edit reward',
      formKey: formKey,
      saving: saving,
      error: submitError,
      onSave: _save,
      width: 560,
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
        ReferenceDropdown(
          table: ReferenceTable.rewardTypes,
          label: 'Reward type',
          value: _typeId,
          canAdd: true,
          onChanged: (value) => setState(() => _typeId = value),
          validator: serverValidator('rewardTypeId', Validators.selection<int>('a reward type')),
        ),
        FieldRow(
          children: [
            TextFormField(
              controller: _value,
              decoration: InputDecoration(
                labelText: isPercentage ? 'Value (%)' : 'Value (KM)',
                prefixIcon: const Icon(Icons.sell_outlined),
                helperText: isPercentage ? 'From 0.01 to 100, for example 10.' : 'From 0.01 to 10000, for example 20.',
              ),
              validator: serverValidator(
                'value',
                Validators.decimalRange('Value', min: 0.01, max: isPercentage ? 100 : 10000),
              ),
            ),
            TextFormField(
              controller: _points,
              decoration: const InputDecoration(
                labelText: 'Points cost',
                prefixIcon: Icon(Icons.loyalty_outlined),
                helperText: 'A whole number from 1 to 100000.',
              ),
              validator: serverValidator('pointsCost', Validators.intRange('Points cost', min: 1, max: 100000)),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active'),
          subtitle: const Text('Clients can redeem only an active reward.'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }
}
