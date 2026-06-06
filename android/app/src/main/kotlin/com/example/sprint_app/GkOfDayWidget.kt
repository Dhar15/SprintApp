package com.example.sprint_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.ComponentName
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class GkOfDayWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val fact = widgetData.getString("gk_of_day_fact",
                "Open the app to load today's GK fact")
                ?: "Open the app to load today's GK fact"

            val category = widgetData.getString("gk_of_day_category", "")
                ?: ""

            val views = RemoteViews(context.packageName, R.layout.gk_of_day_widget)
            views.setTextViewText(R.id.gk_widget_fact, fact)
            views.setTextViewText(R.id.gk_widget_category, category)

            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, launchIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                            android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.gk_widget_fact, pendingIntent)
                views.setOnClickPendingIntent(R.id.gk_widget_category, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, GkOfDayWidget::class.java)
            )
            for (id in appWidgetIds) {
                updateWidget(context, appWidgetManager, id)
            }
        }
    }
}