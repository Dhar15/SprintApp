package com.example.sprint_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WordOfDayWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            android.content.ComponentName(context, WordOfDayWidget::class.java)
        )
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val word = widgetData.getString("word_of_day_word", "Sprint")
                ?: "Sprint"
            val meaning = widgetData.getString("word_of_day_meaning", "Open the app to load today's word")
                ?: "Open the app to load today's word"
                ?: ""

            val views = RemoteViews(context.packageName, R.layout.word_of_day_widget)
            views.setTextViewText(R.id.widget_word, word)
            views.setTextViewText(R.id.widget_meaning, meaning)

            // Tap widget to open app
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, 0, launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                        android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_word, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_meaning, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}