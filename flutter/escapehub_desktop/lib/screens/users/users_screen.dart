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
import 'user_form_dialog.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _search = TextEditingController();
  String? _role;
  bool? _isActive;
  ListSort? _sort;
  var _page = 1;
  late Future<Paged<UserDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<UserDto>> _load() => ref
      .read(apiClientProvider)
      .users
      .list(role: _role, isActive: _isActive, search: optionalText(_search.text), sortBy: _sort, page: _page);

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
    final user = await showUserForm(context);
    if (user == null || !mounted) return;
    _role = null;
    _isActive = null;
    _search.clear();
    _sort = ListSort.newest;
    _reload();
  }

  Future<void> _edit(UserDto user) async {
    if (await showUserForm(context, user) != null && mounted) _reload(page: _page);
  }

  Future<void> _toggleActive(UserDto user) async {
    final api = ref.read(apiClientProvider).users;
    final deactivate = user.isActive;
    final done = await confirmAndRun(
      context,
      title: deactivate ? 'Deactivate the user' : 'Activate the user',
      message: deactivate
          ? 'Do you want to deactivate ${user.fullName}? The user cannot sign in until you activate the account again.'
          : 'Do you want to activate ${user.fullName}? The user can sign in again.',
      confirmLabel: deactivate ? 'Deactivate' : 'Activate',
      destructive: deactivate,
      action: () => deactivate ? api.deactivate(user.id) : api.activate(user.id),
      success: deactivate ? 'The user ${user.username} was deactivated.' : 'The user ${user.username} was activated.',
    );
    if (!done || !mounted) return;
    ref.invalidate(managerOptionsProvider);
    _reload(page: _page);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Name, username or email', onChanged: (_) => _filter()),
        FilterDropdown<String>(
          label: 'Role',
          value: _role,
          options: {for (final role in Roles.staff) role: roleLabel(role)},
          onChanged: (value) => _filter(() => _role = value),
        ),
        FilterDropdown<bool>(
          label: 'Status',
          value: _isActive,
          options: const {true: 'Active', false: 'Inactive'},
          onChanged: (value) => _filter(() => _isActive = value),
        ),
      ],
      actions: [FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('New user'))],
      child: PagedTable<UserDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        onTap: _edit,
        columns: const ['User', 'Email', 'Phone', 'Role', 'City', 'Status', 'Actions'],
        cells: (user) => [
          NameWithImage(name: user.fullName, imageUrl: user.profilePictureUrl, subtitle: user.username, round: true),
          Text(user.email),
          Text(user.phone ?? 'No phone'),
          Text(roleLabel(user.role)),
          Text(user.cityName ?? 'No city'),
          StatusChip(user.isActive ? 'Active' : 'Inactive', Tone.ofActive(user.isActive)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionIcon(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: () => _edit(user)),
              ActionIcon(
                icon: user.isActive ? Icons.person_off_outlined : Icons.person_outline,
                tooltip: user.id == me?.id
                    ? 'You cannot deactivate your own account.'
                    : (user.isActive ? 'Deactivate' : 'Activate'),
                onPressed: user.id == me?.id ? null : () => _toggleActive(user),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
