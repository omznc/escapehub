import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import 'empty_view.dart';

class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    this.reloadKey,
    this.refreshKey,
    this.itemKey,
    this.header,
    this.spacing = 8,
    this.exclude,
  });

  final Future<Paged<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyMessage;
  final Object? reloadKey;
  final Object? refreshKey;
  final Object Function(T item)? itemKey;
  final Widget? header;
  final double spacing;
  final bool Function(T item)? exclude;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  List<T> _items = [];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = false;
  Object? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  @override
  void didUpdateWidget(PagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadKey != widget.reloadKey) {
      _load(1);
    } else if (oldWidget.refreshKey != widget.refreshKey) {
      _refreshFirstPage();
    }
  }

  List<T> _merge(List<T> first, List<T> rest) {
    final key = widget.itemKey;
    if (key == null) return [...first, ...rest];
    final seen = first.map(key).toSet();
    return [...first, ...rest.where((item) => !seen.contains(key(item)))];
  }

  Future<void> _refreshFirstPage() async {
    final request = _request;
    final Paged<T> result;
    try {
      result = await widget.fetch(1);
    } on ApiException {
      return;
    }
    if (!mounted || request != _request || _error != null) return;
    setState(() {
      _items = _merge(result.items, _items);
      _hasMore = _items.length < result.totalCount;
    });
  }

  Future<void> _load(int page) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.fetch(page);
      if (!mounted || request != _request) return;
      setState(() {
        _items = page == 1 ? result.items : _merge(_items, result.items);
        _page = page;
        _hasMore = result.hasMore;
      });
    } on ApiException catch (error) {
      if (!mounted || request != _request) return;
      if (page == 1) {
        setState(() => _error = error);
      } else {
        showErrorSnackBar(context, error);
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(1),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [?widget.header, ..._content(context)],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final error = _error;
    if (error != null) return [ErrorView(error: error, onRetry: () => _load(1))];
    if (_items.isEmpty) {
      return [
        _loading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : EmptyView(icon: widget.emptyIcon, message: widget.emptyMessage),
      ];
    }
    return [
      for (final item in _items.where((item) => !(widget.exclude?.call(item) ?? false)))
        Padding(
          padding: EdgeInsets.only(bottom: widget.spacing),
          child: widget.itemBuilder(context, item),
        ),
      if (_hasMore) _loadMoreButton(),
    ];
  }

  Widget _loadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _loading ? null : () => _load(_page + 1),
          icon: _loading
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.expand_more),
          label: const Text('Load more'),
        ),
      ),
    );
  }
}
