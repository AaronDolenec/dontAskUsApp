import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../utils/utils.dart';

class ResultChart extends StatelessWidget {
  final Map<String, int> results;
  final int totalVotes;
  final String? userAnswer;
  final bool showPercentages;

  const ResultChart({
    super.key,
    required this.results,
    required this.totalVotes,
    this.userAnswer,
    this.showPercentages = true,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text('No results yet'),
      );
    }

    final sortedEntries = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar Chart
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: sortedEntries.first.value.toDouble() * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = sortedEntries[group.x.toInt()];
                    final percentage = totalVotes > 0
                        ? (entry.value / totalVotes * 100).toStringAsFixed(1)
                        : '0';
                    return BarTooltipItem(
                      '${entry.key}\n${entry.value} votes ($percentage%)',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= sortedEntries.length) {
                        return const SizedBox.shrink();
                      }
                      final entry = sortedEntries[value.toInt()];
                      final isUserAnswer = entry.key == userAnswer;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _truncateLabel(entry.key),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUserAnswer 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: isUserAnswer 
                                ? AppColors.primary 
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  
                ),
                rightTitles: const AxisTitles(
                  
                ),
              ),
              gridData: FlGridData(
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[200],
                    strokeWidth: 1,
                  );
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(sortedEntries.length, (index) {
                final entry = sortedEntries[index];
                final isUserAnswer = entry.key == userAnswer;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: isUserAnswer 
                          ? AppColors.primary 
                          : _getBarColor(index),
                      width: 24,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Legend / Details
        if (showPercentages) ...[
          Text(
            'Vote Distribution',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...sortedEntries.map((entry) {
            final percentage = totalVotes > 0
                ? (entry.value / totalVotes * 100).toStringAsFixed(1)
                : '0';
            final isUserAnswer = entry.key == userAnswer;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isUserAnswer 
                          ? AppColors.primary 
                          : _getBarColor(sortedEntries.indexOf(entry)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: isUserAnswer 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} ($percentage%)',
                    style: TextStyle(
                      fontWeight: isUserAnswer 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _truncateLabel(String label) {
    if (label.length <= 10) return label;
    return '${label.substring(0, 8)}...';
  }

  Color _getBarColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}

class ResultPieChart extends StatelessWidget {
  final Map<String, int> results;
  final int totalVotes;
  final String? userAnswer;

  const ResultPieChart({
    super.key,
    required this.results,
    required this.totalVotes,
    this.userAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text('No results yet'),
      );
    }

    final sortedEntries = results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(sortedEntries.length, (index) {
                final entry = sortedEntries[index];
                final percentage = totalVotes > 0
                    ? entry.value / totalVotes * 100
                    : 0.0;
                final isUserAnswer = entry.key == userAnswer;
                
                return PieChartSectionData(
                  color: isUserAnswer 
                      ? AppColors.primary 
                      : _getBarColor(index),
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: isUserAnswer ? 60 : 50,
                  titleStyle: TextStyle(
                    fontSize: isUserAnswer ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: sortedEntries.map((entry) {
            final isUserAnswer = entry.key == userAnswer;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isUserAnswer 
                        ? AppColors.primary 
                        : _getBarColor(sortedEntries.indexOf(entry)),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isUserAnswer 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getBarColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}
