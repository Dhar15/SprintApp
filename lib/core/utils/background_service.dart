import 'package:workmanager/workmanager.dart';
import 'package:home_widget/home_widget.dart';
import '../../features/word_of_day/services/word_of_day_service.dart';
import '../../features/gk_card/services/gk_service.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void backgroundCallback() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'dailyRefresh') {
      // Word of the Day
      try {
        final wordService = WordOfDayService();
        final word = await wordService.getWordOfDay();
        if (word != null) {
          await HomeWidget.saveWidgetData('word_of_day_word', word.word);
          await HomeWidget.saveWidgetData('word_of_day_meaning', word.meaning);
          await HomeWidget.updateWidget(androidName: 'WordOfDayWidget');
        }
      } catch (e) {
        print('Word of Day background error: $e');
      }

      // GK of the Day
      try {
        final gkService = GkService();
        final fact = await gkService.getFactOfDay();
        if (fact != null) {
          await HomeWidget.updateWidget(androidName: 'GkOfDayWidget');
        }
      } catch (e) {
        print('GK of Day background error: $e');
      }

      // Re-schedule for the same time tomorrow
      await StorageService.instance.init();
      final hour = StorageService.instance.getWidgetRefreshHour();
      final minute = StorageService.instance.getWidgetRefreshMinute();
      await scheduleDailyRefresh(hour, minute);
    }
    return Future.value(true);
  });
}

/// Schedules a one-off task to fire at the next occurrence of [hour]:[minute].
Future<void> scheduleDailyRefresh(int hour, int minute) async {
  final now = DateTime.now();
  var target = DateTime(now.year, now.month, now.day, hour, minute);
  if (target.isBefore(now) || target.isAtSameMomentAs(now)) {
    target = target.add(const Duration(days: 1));
  }
  final delay = target.difference(now);

  await Workmanager().cancelByUniqueName('dailyRefresh');
  await Workmanager().registerOneOffTask(
    'dailyRefresh',
    'dailyRefresh',
    initialDelay: delay,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}