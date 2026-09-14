import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/storage_summary.dart';

/// A reactive pie chart that visualises the storage breakdown by category.
class StoragePieChart extends StatefulWidget {
  const StoragePieChart({
    super.key,
    required this.summary,
  });

  final StorageSummary summary;

  @override
  State<StoragePieChart> createState() => _StoragePieChartState();
}

class _StoragePieChartState extends State<StoragePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.summary.totalBytes == 0) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('No storage data available.')),
      );
    }

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _showingSections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(FileCategory.values.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final fontSize = isTouched ? 16.0 : 12.0;
      
      final category = FileCategory.values[i];
      final value = widget.summary.fractionForCategory(category);
      final bytes = widget.summary.bytesPerCategory[category] ?? 0;
      
      // Don't show sections for empty categories
      if (value == 0) {
         return PieChartSectionData(value: 0, radius: 0, title: '');
      }

      return PieChartSectionData(
        color: category.color,
        value: value,
        title: '${(value * 100).toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }
}
