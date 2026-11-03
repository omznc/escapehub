import 'dart:math' as math;

import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import 'pages.dart';

class PagedTable<T> extends StatelessWidget {
  const PagedTable({
    super.key,
    required this.future,
    required this.columns,
    required this.cells,
    required this.onPage,
    required this.onRetry,
    this.onTap,
    this.emptyMessage = 'No records match the search and the filters.',
  });

  final Future<Paged<T>> future;
  final List<String> columns;
  final List<Widget> Function(T item) cells;
  final ValueChanged<int> onPage;
  final VoidCallback onRetry;
  final ValueChanged<T>? onTap;
  final String emptyMessage;

  void _showLastPage(Paged<T> page) {
    final last = math.max(page.totalPages, 1);
    if (page.page > last) WidgetsBinding.instance.addPostFrameCallback((_) => onPage(last));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Paged<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: onRetry);
        final page = snapshot.data;
        if (page == null) return const Center(child: CircularProgressIndicator());
        final loading = snapshot.connectionState == ConnectionState.waiting;
        if (!loading) _showLastPage(page);
        return Column(
          children: [
            SizedBox(height: 2, child: loading ? const LinearProgressIndicator() : null),
            Expanded(child: page.items.isEmpty ? EmptyMessage(emptyMessage) : _table(page.items)),
            const Divider(height: 1),
            Pager(page: page, onPage: onPage),
          ],
        );
      },
    );
  }

  Widget _table(List<T> items) {
    final tap = onTap;
    return WideTable(
      table: DataTable(
        showCheckboxColumn: false,
        columnSpacing: 28,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 68,
        columns: [for (final column in columns) DataColumn(label: Text(column))],
        rows: [
          for (final item in items)
            DataRow(
              onSelectChanged: tap == null ? null : (_) => tap(item),
              cells: [for (final cell in cells(item)) DataCell(cell)],
            ),
        ],
      ),
    );
  }
}

class WideTable extends StatefulWidget {
  const WideTable({super.key, required this.table});

  final Widget table;

  @override
  State<WideTable> createState() => _WideTableState();
}

class _WideTableState extends State<WideTable> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _horizontal,
        thumbVisibility: true,
        notificationPredicate: (notification) => notification.depth == 1,
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: widget.table,
            ),
          ),
        ),
      ),
    );
  }
}

class Pager extends StatelessWidget {
  const Pager({super.key, required this.page, required this.onPage});

  final Paged<Object?> page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final totalPages = page.totalPages == 0 ? 1 : page.totalPages;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(page.totalCount == 1 ? '1 record' : '${page.totalCount} records'),
          const Spacer(),
          IconButton(
            tooltip: 'Previous page',
            onPressed: page.page > 1 ? () => onPage(page.page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page ${page.page} of $totalPages'),
          IconButton(
            tooltip: 'Next page',
            onPressed: page.hasMore ? () => onPage(page.page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class NameWithImage extends StatelessWidget {
  const NameWithImage({super.key, required this.name, required this.imageUrl, this.subtitle, this.round = false});

  final String name;
  final String? imageUrl;
  final String? subtitle;
  final bool round;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ApiImage(
          path: imageUrl,
          label: name,
          width: 40,
          height: 40,
          borderRadius: BorderRadius.circular(round ? 20 : 6),
        ),
        const SizedBox(width: 12),
        TwoLineText(title: name, subtitle: subtitle),
      ],
    );
  }
}

class TwoLineText extends StatelessWidget {
  const TwoLineText({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final details = subtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        if (details != null) Text(details, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class ActionIcon extends StatelessWidget {
  const ActionIcon({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(onPressed: onPressed, icon: Icon(icon)),
    );
  }
}
