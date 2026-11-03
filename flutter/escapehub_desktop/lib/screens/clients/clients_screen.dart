import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../format.dart';
import '../../widgets/filters.dart';
import '../../widgets/paged_table.dart';
import '../../widgets/pages.dart';
import '../../widgets/status_chip.dart';
import 'client_detail_screen.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _search = TextEditingController();
  bool? _isActive;
  var _page = 1;
  late Future<Paged<UserDto>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<Paged<UserDto>> _load() =>
      ref.read(apiClientProvider).clients.list(isActive: _isActive, search: optionalText(_search.text), page: _page);

  void _reload({int page = 1}) => setState(() {
    _page = page;
    _future = _load();
  });

  Future<void> _open(UserDto client) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClientDetailScreen(clientId: client.id)));
    if (mounted) _reload(page: _page);
  }

  @override
  Widget build(BuildContext context) {
    return ListPage(
      filters: [
        SearchField(controller: _search, hint: 'Name, username or email', onChanged: (_) => _reload()),
        FilterDropdown<bool>(
          label: 'Status',
          value: _isActive,
          options: const {true: 'Active', false: 'Inactive'},
          onChanged: (value) {
            _isActive = value;
            _reload();
          },
        ),
      ],
      child: PagedTable<UserDto>(
        future: _future,
        onPage: (page) => _reload(page: page),
        onRetry: () => _reload(page: _page),
        onTap: _open,
        columns: const ['Client', 'Email', 'Phone', 'City', 'Member since', 'Status'],
        cells: (client) => [
          NameWithImage(
            name: client.fullName,
            imageUrl: client.profilePictureUrl,
            subtitle: client.username,
            round: true,
          ),
          Text(client.email),
          Text(client.phone ?? 'No phone'),
          Text(client.cityName ?? 'No city'),
          Text(formatDate(client.createdAt)),
          StatusChip(client.isActive ? 'Active' : 'Inactive', Tone.ofActive(client.isActive)),
        ],
      ),
    );
  }
}
