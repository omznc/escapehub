import 'package:escapehub_core/escapehub_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../format.dart';
import '../../widgets/charts.dart';
import '../../widgets/filters.dart';
import '../../widgets/pages.dart';
import 'report_data.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  var _type = ReportType.bookings;
  var _range = DateTimeRange(start: addDays(today(), -90), end: today());
  int? _roomId;
  var _top = 10;
  var _groupBy = ReportGroupBy.month;
  var _exporting = false;
  late Future<ReportData> _future = _load();

  ReportsApi get _api => ref.read(apiClientProvider).reports;

  ReportQuery get _query => ReportQuery(
    from: _range.start,
    to: _range.end,
    roomId: _type.usesRoom ? _roomId : null,
    top: _type.usesTop ? _top : null,
    groupBy: _type.usesGroupBy ? _groupBy : null,
  );

  Future<ReportData> _load() => loadReport(_api, _type, _query);

  void _filter(VoidCallback change) => setState(() {
    change();
    _future = _load();
  });

  Future<ExportedFile?> _download(ExportFormat format) async {
    setState(() => _exporting = true);
    try {
      return await _api.export(_type, format, _query);
    } on ApiException catch (error) {
      if (mounted) showErrorSnackBar(context, error);
      return null;
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _save(ExportFormat format) async {
    final file = await _download(format);
    if (file == null) return;
    final location = await FilePicker.saveFile(
      fileName: file.fileName,
      bytes: file.bytes,
      mimeType: file.contentType,
      dialogTitle: 'Save the report',
      type: FileType.custom,
      allowedExtensions: [format.name],
    );
    if (location != null && mounted) showSuccessSnackBar(context, 'The report ${file.fileName} was saved.');
  }

  Future<void> _print() async {
    final file = await _download(ExportFormat.pdf);
    if (file == null) return;
    await Printing.layoutPdf(name: file.fileName, onLayout: (_) async => file.bytes);
  }

  @override
  Widget build(BuildContext context) {
    final isAdministrator = ref.watch(currentUserProvider.select((user) => user?.isAdministrator ?? false));
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportList(
            types: [
              for (final type in ReportType.values)
                if (isAdministrator || !type.adminOnly) type,
            ],
            selected: _type,
            onSelected: (type) => _filter(() => _type = type),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: ListPage(
              filters: _filters(),
              actions: [
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _save(ExportFormat.pdf),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Save as PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _save(ExportFormat.csv),
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('Save as CSV'),
                ),
                FilledButton.icon(
                  onPressed: _exporting ? null : _print,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                ),
              ],
              child: FutureView<ReportData>(
                future: _future,
                onRetry: () => _filter(() {}),
                builder: (context, data) => _ReportView(data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _filters() => [
    DateRangeFilter(value: _range, allowClear: false, onChanged: (value) => _filter(() => _range = value ?? _range)),
    if (_type.usesRoom) RoomFilter(value: _roomId, onChanged: (value) => _filter(() => _roomId = value)),
    if (_type.usesTop)
      FilterDropdown<int>(
        label: 'Rows',
        value: _top,
        allLabel: null,
        width: 140,
        options: const {5: 'Top 5', 10: 'Top 10', 20: 'Top 20', 50: 'Top 50'},
        onChanged: (value) => _filter(() => _top = value ?? _top),
      ),
    if (_type.usesGroupBy)
      FilterDropdown<ReportGroupBy>(
        label: 'Group by',
        value: _groupBy,
        allLabel: null,
        width: 160,
        options: const {ReportGroupBy.day: 'Day', ReportGroupBy.month: 'Month'},
        onChanged: (value) => _filter(() => _groupBy = value ?? _groupBy),
      ),
  ];
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.types, required this.selected, required this.onSelected});

  final List<ReportType> types;
  final ReportType selected;
  final ValueChanged<ReportType> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 250,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final type in types)
            ListTile(
              dense: true,
              selected: type == selected,
              selectedColor: colors.onSecondaryContainer,
              selectedTileColor: colors.secondaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.description_outlined),
              title: Text(type.label),
              onTap: () => onSelected(type),
            ),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(data.title, style: theme.textTheme.titleLarge),
        Text('Period: ${formatDateRange(data.from, data.to)}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Text(data.chartTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SimpleBarChart(points: data.chart, format: data.format),
        const SizedBox(height: 24),
        if (data.rows.isEmpty)
          const EmptyMessage('There is no data for this period.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 28,
              columns: [for (final column in data.columns) DataColumn(label: Text(column))],
              rows: [
                for (final row in data.rows) DataRow(cells: [for (final cell in row) DataCell(Text(cell))]),
              ],
            ),
          ),
      ],
    );
  }
}
