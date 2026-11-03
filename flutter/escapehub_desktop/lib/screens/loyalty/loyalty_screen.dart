import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../providers.dart';
import '../../widgets/actions.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/status_chip.dart';
import '../shell/section.dart';
import 'reward_form_dialog.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Rewards catalog'),
            Tab(text: 'Transactions'),
            Tab(text: 'Redemptions'),
          ],
        ),
        body: const TabBarView(children: [_RewardsTab(), _TransactionsTab(), _RedemptionsTab()]),
      ),
    );
  }
}

class _RewardsTab extends ConsumerStatefulWidget {
  const _RewardsTab();

  @override
  ConsumerState<_RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends ConsumerState<_RewardsTab> {
  final _search = TextEditingController();
  bool? _isActive;
  int? _typeId;
  ListSort? _sort;
  var _page = 1;
  late Future<Paged<LoyaltyRewardDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<LoyaltyRewardDto>> _load() => ref
      .read(apiClientProvider)
      .loyalty
      .rewards(
        isActive: _isActive,
        rewardTypeId: _typeId,
        search: optionalText(_search.text),
        sortBy: _sort,
        page: _page,
      );

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  void _filter([VoidCallback? change]) {
    change?.call();
    _sort = null;
    _reload();
  }

  Future<void> _create() async {
    final reward = await showRewardForm(context);
    if (reward == null || !mounted) return;
    _isActive = null;
    _typeId = null;
    _search.clear();
    _sort = ListSort.newest;
    _reload();
  }

  Future<void> _edit(LoyaltyRewardDto reward) async {
    final saved = await showRewardForm(context, reward);
    if (saved == null || !mounted) return;
    if (_search.text == reward.name) _search.text = saved.name;
    _reload(page: _page);
  }

  Future<void> _delete(LoyaltyRewardDto reward) async {
    final done = await confirmAndRun(
      context,
      title: 'Delete the reward',
      message: 'Do you want to delete the reward ${reward.name}? You cannot undo this action.',
      confirmLabel: 'Delete',
      destructive: true,
      action: () => ref.read(apiClientProvider).loyalty.deleteReward(reward.id),
      success: 'The reward ${reward.name} was deleted.',
    );
    if (done && mounted) _reload(page: _page);
  }

  String? _createBlockedReason() {
    final types = ref.watch(referenceProvider(ReferenceTable.rewardTypes)).value;
    return types != null && types.isEmpty ? 'Add a reward type in Reference data first.' : null;
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _createBlockedReason();
    return ListPage(
      header: const _EarningRules(),
      filters: [
        SearchField(controller: _search, hint: 'Reward name', onChanged: (_) => _filter()),
        ReferenceFilter(
          table: ReferenceTable.rewardTypes,
          label: 'Reward type',
          value: _typeId,
          onChanged: (value) => _filter(() => _typeId = value),
        ),
        FilterDropdown<bool>(
          label: 'Status',
          value: _isActive,
          options: const {true: 'Active', false: 'Inactive'},
          onChanged: (value) => _filter(() => _isActive = value),
        ),
      ],
      actions: [
        Tooltip(
          message: blocked ?? 'Add a new reward',
          child: FilledButton.icon(
            onPressed: blocked == null ? _create : null,
            icon: const Icon(Icons.add),
            label: const Text('New reward'),
          ),
        ),
      ],
      child: PagedTable<LoyaltyRewardDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        onTap: _edit,
        columns: const ['Reward', 'Type', 'Value', 'Points cost', 'Redemptions', 'Status', 'Actions'],
        cells: (reward) => [
          SizedBox(
            width: 320,
            child: TwoLineText(title: reward.name, subtitle: reward.description),
          ),
          Text(reward.rewardTypeName),
          Text(formatDiscount(reward.value, isPercentage: reward.isPercentage)),
          Text('${reward.pointsCost} points'),
          Text('${reward.redemptionCount}'),
          StatusChip(reward.isActive ? 'Active' : 'Inactive', Tone.ofActive(reward.isActive)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionIcon(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: () => _edit(reward)),
              ActionIcon(
                icon: Icons.delete_outline,
                tooltip: reward.deleteBlockedReason ?? 'Delete',
                onPressed: reward.canDelete == true ? () => _delete(reward) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningRules extends ConsumerStatefulWidget {
  const _EarningRules();

  @override
  ConsumerState<_EarningRules> createState() => _EarningRulesState();
}

class _EarningRulesState extends ConsumerState<_EarningRules> {
  late final Future<SettingsDto> _settings = ref.read(apiClientProvider).settings.get();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.rule_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<SettingsDto>(
                future: _settings,
                builder: (context, snapshot) => Text(switch (snapshot) {
                  AsyncSnapshot(:final data?) =>
                    'Earning rules: clients get ${data.pointsPerPlayer} points for each player '
                        'and ${formatNumber(data.pointsPerCurrencyUnit)} points for each KM paid.',
                  AsyncSnapshot(:final error?) => '$error',
                  _ => 'Loading the earning rules.',
                }),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(sectionProvider.notifier).open(Section.settings),
              child: const Text('Change the rules in Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsTab extends ConsumerStatefulWidget {
  const _TransactionsTab();

  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab> {
  final _search = TextEditingController();
  TransactionType? _type;
  DateTimeRange? _range;
  var _page = 1;
  late Future<Paged<LoyaltyTransactionDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<LoyaltyTransactionDto>> _load() => ref
      .read(apiClientProvider)
      .loyalty
      .transactions(type: _type, from: _range?.start, to: _range?.end, search: optionalText(_search.text), page: _page);

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  void _filter(VoidCallback change) {
    change();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Client or description', onChanged: (_) => _reload()),
        FilterDropdown<TransactionType>(
          label: 'Type',
          value: _type,
          options: {for (final type in TransactionType.values) type: type.value},
          onChanged: (value) => _filter(() => _type = value),
        ),
        DateRangeFilter(value: _range, onChanged: (value) => _filter(() => _range = value)),
      ],
      child: PagedTable<LoyaltyTransactionDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        columns: const ['Date', 'Client', 'Type', 'Points', 'Description', 'Room'],
        cells: (transaction) => [
          Text(formatTimestamp(transaction.createdAt)),
          NameWithImage(name: transaction.clientName, imageUrl: transaction.clientPictureUrl, round: true),
          Text(transaction.type.value),
          Text(transaction.points > 0 ? '+${transaction.points}' : '${transaction.points}'),
          SizedBox(width: 320, child: Text(transaction.description ?? '', maxLines: 2)),
          switch (transaction.roomName) {
            final room? => NameWithImage(name: room, imageUrl: transaction.roomImageUrl),
            null => const Text(''),
          },
        ],
      ),
    );
  }
}

class _RedemptionsTab extends ConsumerStatefulWidget {
  const _RedemptionsTab();

  @override
  ConsumerState<_RedemptionsTab> createState() => _RedemptionsTabState();
}

class _RedemptionsTabState extends ConsumerState<_RedemptionsTab> {
  final _search = TextEditingController();
  bool? _isUsed;
  DateTimeRange? _range;
  var _page = 1;
  late Future<Paged<RewardRedemptionDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<RewardRedemptionDto>> _load() => ref
      .read(apiClientProvider)
      .loyalty
      .redemptions(
        isUsed: _isUsed,
        from: _range?.start,
        to: _range?.end,
        search: optionalText(_search.text),
        page: _page,
      );

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  void _filter(VoidCallback change) {
    change();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Code, reward or client', onChanged: (_) => _reload()),
        FilterDropdown<bool>(
          label: 'Voucher',
          value: _isUsed,
          options: const {true: 'Used', false: 'Not used'},
          onChanged: (value) => _filter(() => _isUsed = value),
        ),
        DateRangeFilter(value: _range, onChanged: (value) => _filter(() => _range = value)),
      ],
      child: PagedTable<RewardRedemptionDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        columns: const ['Redeemed', 'Client', 'Reward', 'Value', 'Points', 'Voucher code', 'Status'],
        cells: (redemption) => [
          Text(formatTimestamp(redemption.redeemedAt)),
          NameWithImage(name: redemption.clientName, imageUrl: redemption.clientPictureUrl, round: true),
          Text(redemption.rewardName),
          Text(formatDiscount(redemption.value, isPercentage: redemption.isPercentage)),
          Text('${redemption.pointsSpent}'),
          SelectableText(redemption.code),
          switch (redemption.usedAt) {
            final usedAt? => StatusChip('Used on ${formatDate(usedAt)}', Tone.neutral),
            null => const StatusChip('Not used', Tone.positive),
          },
        ],
      ),
    );
  }
}
