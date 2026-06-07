import 'package:workmanager/workmanager.dart';
import 'package:home_widget/home_widget.dart';
import '../../features/word_of_day/services/word_of_day_service.dart';
import '../../features/gk_card/services/gk_service.dart';

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
    }
    return Future.value(true);
  });
}