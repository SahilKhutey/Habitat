// Habitat Interactive 7-Day Completion Bar Chart
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/daily_summary.dart';
import '../../domain/models/weekly_summary.dart';

class DailyGraph extends StatefulWidget {
  final WeeklyProgressSummaryModel weekSummary;
  final ValueChanged<DailyProgressSummaryModel>? onSelectDay;

  const DailyGraph({
    super.key,
    required this.weekSummary,
    this.onSelectDay,
  });

  @override
  State<DailyGraph> createState() => _DailyGraphState();
}

class _DailyGraphState extends State<DailyGraph> {
  int? _selectedDayIndex;

  @override
  Widget build(BuildContext context) {
    final days = widget.weekSummary.days;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-DAY COMPLETION TREND',
                style: TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
              Text(
                'Avg: ${widget.weekSummary.averageCompletionPercentage.toInt()}%',
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: HabitatTheme.growthGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-Day Vertical Bar Grid
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                final day = days[index];
                final isToday = day.date.year == now.year &&
                    day.date.month == now.month &&
                    day.date.day == now.day;
                final isSelected = _selectedDayIndex == index;
                final score = day.completionPercentage;
                final heightFactor = (score / 100.0).clamp(0.08, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedDayIndex = index);
                        if (widget.onSelectDay != null) {
                          widget.onSelectDay!(day);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSelected || isToday)
                            Text(
                              '$score%',
                              style: TextStyle(
                                fontFamily: HabitatTheme.fontHeading,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isToday
                                    ? HabitatTheme.growthGreen
                                    : Colors.white,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: 70 * heightFactor,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? HabitatTheme.growthGreen
                                  : isSelected
                                      ? HabitatTheme.youngLeaf
                                      : score > 0
                                          ? HabitatTheme.habitatGreen
                                          : HabitatTheme.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isToday || isSelected
                                    ? HabitatTheme.growthGreen
                                    : HabitatTheme.surfaceBorder,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day.dayName,
                            style: TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontSize: 10,
                              fontWeight:
                                  isToday ? FontWeight.w900 : FontWeight.w600,
                              color: isToday
                                  ? Colors.white
                                  : HabitatTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Detail tooltip row if a day is selected
          if (_selectedDayIndex != null &&
              _selectedDayIndex! < days.length) ...[
            const Divider(height: 20, color: HabitatTheme.surfaceBorder),
            _buildDayDetailRow(days[_selectedDayIndex!]),
          ],
        ],
      ),
    );
  }

  Widget _buildDayDetailRow(DailyProgressSummaryModel day) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${day.dayName} Details:',
          style: const TextStyle(
            fontFamily: HabitatTheme.fontHeading,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          '${day.completedCount} / ${day.scheduledCount} completed (${day.completionPercentage}%)',
          style: const TextStyle(
            fontFamily: HabitatTheme.fontBody,
            fontSize: 12,
            color: HabitatTheme.growthGreen,
          ),
        ),
      ],
    );
  }
}
