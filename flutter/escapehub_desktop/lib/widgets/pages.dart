import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key, required this.filters, required this.child, this.actions = const [], this.header});

  final List<Widget> filters;
  final List<Widget> actions;
  final Widget child;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final top = header;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (top != null) ...[top, const SizedBox(height: 16)],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: filters,
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(spacing: 8, children: actions),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(clipBehavior: Clip.antiAlias, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.title, required this.body, this.actions = const [], this.bottom});

  final String title;
  final Widget body;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 112,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
        title: Text(title),
        actions: [...actions, const SizedBox(width: 16)],
        bottom: bottom,
      ),
      body: body,
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.actions = const []});

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                ...actions,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 170,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.message, {super.key, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: colors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class FutureView<T> extends StatelessWidget {
  const FutureView({super.key, required this.future, required this.onRetry, required this.builder});

  final Future<T> future;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: onRetry);
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return builder(context, snapshot.requireData);
      },
    );
  }
}
