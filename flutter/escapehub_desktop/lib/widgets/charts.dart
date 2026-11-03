import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'pages.dart';

class ChartPoint {
  const ChartPoint(this.label, this.value);

  final String label;
  final double value;
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.points, required this.format, this.height = 260});

  final List<ChartPoint> points;
  final String Function(double value) format;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return SizedBox(height: height, child: const EmptyMessage('There is no data for this chart.'));
    final colors = Theme.of(context).colorScheme;
    final highest = points.map((point) => point.value).reduce(max);
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) => _chart(context, colors, highest, constraints.maxWidth)),
    );
  }

  BarChart _chart(BuildContext context, ColorScheme colors, double highest, double width) {
    return BarChart(
      BarChartData(
        maxY: highest == 0 ? 1 : highest * 1.15,
        gridData: _grid(colors),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, points, width),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${points[group.x].label}\n${format(rod.toY)}',
              TextStyle(color: colors.onInverseSurface),
            ),
          ),
        ),
        barGroups: [
          for (final (index, point) in points.indexed)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: point.value,
                  color: colors.primary,
                  width: points.length > 30 ? 6 : 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({super.key, required this.points, required this.format, this.height = 260});

  final List<ChartPoint> points;
  final String Function(double value) format;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return SizedBox(height: height, child: const EmptyMessage('There is no data for this chart.'));
    final colors = Theme.of(context).colorScheme;
    final highest = points.map((point) => point.value).reduce(max);
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) => _chart(context, colors, highest, constraints.maxWidth)),
    );
  }

  LineChart _chart(BuildContext context, ColorScheme colors, double highest, double width) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: highest == 0 ? 1 : highest * 1.15,
        gridData: _grid(colors),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, points, width),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.inverseSurface,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${points[spot.x.toInt()].label}\n${format(spot.y)}',
                  TextStyle(color: colors.onInverseSurface),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final (index, point) in points.indexed) FlSpot(index.toDouble(), point.value)],
            color: colors.primary,
            barWidth: 2,
            dotData: FlDotData(show: points.length <= 31),
          ),
        ],
      ),
    );
  }
}

const double _axisWidth = 48;

FlGridData _grid(ColorScheme colors) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(color: colors.outlineVariant, strokeWidth: 1),
);

FlTitlesData _titles(BuildContext context, List<ChartPoint> points, double width) {
  final style = Theme.of(context).textTheme.bodySmall;
  final step = max(1, (points.length / 10).ceil());
  final labelWidth = max(24.0, (width - _axisWidth) / points.length * step - 12);
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: _axisWidth,
        getTitlesWidget: (value, meta) {
          if (value == meta.max) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(meta.formattedValue, style: style),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index % step != 0 || index >= points.length) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: SizedBox(
              width: labelWidth,
              child: Text(
                points[index].label,
                style: style,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    ),
  );
}
