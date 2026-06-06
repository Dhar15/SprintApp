import 'package:workmanager/workmanager.dart';
import 'package:home_widget/home_widget.dart';
import '../../features/word_of_day/services/word_of_day_service.dart';

// This runs in a separate isolate — must be a top-level function
@pragma('vm:entry-point')
void backgroundCallback() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'fetchWordOfDay') {
      final service = WordOfDayService();
      final word = await service.getWordOfDay();
      if (word != null) {
        await HomeWidget.saveWidgetData('word_of_day_word', word.word);
        await HomeWidget.saveWidgetData('word_of_day_meaning', word.meaning);
        await HomeWidget.updateWidget(androidName: 'WordOfDayWidget');
      }
    }
    return Future.value(true);
  });
}