import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_service.dart';

class StreakCalendarSheet extends StatelessWidget {
  const StreakCalendarSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const StreakCalendarSheet(),
    );
  }

  @override
    Widget build(BuildContext context) {
    final playedDays = StorageService.instance.getPlayedDays();
    final streak = StorageService.instance.getStreak();
    final today = DateTime.now();

    final months = List.generate(3, (i) {
        return DateTime(today.year, today.month - i, 1);
    }).toList();

    return Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
        children: [
            // Handle
            Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
            ),
            ),
            const SizedBox(height: 20),
            // Fixed header
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
                children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                        streak > 0 ? '🔥 $streak day streak' : 'No streak yet',
                        style: GoogleFonts.dmSans(
                        color: streak > 0 ? AppColors.warning : AppColors.textSecondary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        ),
                    ),
                    Text(
                        '${playedDays.length} total days played',
                        style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        ),
                    ),
                    ],
                ),
                const Spacer(),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                    _LegendItem(emoji: '🔥', label: 'Played'),
                    const SizedBox(height: 4),
                    _LegendItem(emoji: '⭕', label: 'Today'),
                    ],
                ),
                ],
            ),
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.border, height: 1),
            // Scrollable area only
            Expanded(
            child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: months.length,
                itemBuilder: (_, i) => _MonthGrid(
                month: months[i],
                playedDays: playedDays,
                today: today,
                ),
            ),
            ),
        ],
        ),
    );
    }
}

class _LegendItem extends StatelessWidget {
  final String emoji;
  final String label;
  const _LegendItem({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Set<String> playedDays;
  final DateTime today;

  const _MonthGrid({
    required this.month,
    required this.playedDays,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7; // 0=Sun
    final monthLabel = _monthName(month.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          '$monthLabel ${month.year}',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        // Day of week headers
        Row(
          children: ['S','M','T','W','T','F','S'].map((d) => Expanded(
            child: Center(
              child: Text(
                d,
                style: GoogleFonts.dmSans(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // Day grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: daysInMonth + firstWeekday,
          itemBuilder: (_, index) {
            if (index < firstWeekday) return const SizedBox.shrink();
            final day = index - firstWeekday + 1;
            final date = DateTime(month.year, month.month, day);
            final dateStr = date.toIso8601String().substring(0, 10);
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isPlayed = playedDays.contains(dateStr);
            final isFuture = date.isAfter(today);

            return _DayCell(
              day: day,
              isToday: isToday,
              isPlayed: isPlayed,
              isFuture: isFuture,
            );
          },
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[month - 1];
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isPlayed;
  final bool isFuture;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isPlayed,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlayed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            Text(
              day.toString(),
              style: GoogleFonts.dmSans(
                color: AppColors.warning,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isToday ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppColors.accent.withOpacity(0.5))
            : null,
      ),
      child: Center(
        child: isToday
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭕', style: TextStyle(fontSize: 13)),
                  Text(
                    day.toString(),
                    style: GoogleFonts.dmSans(
                      color: AppColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                day.toString(),
                style: GoogleFonts.dmSans(
                  color: isFuture
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}