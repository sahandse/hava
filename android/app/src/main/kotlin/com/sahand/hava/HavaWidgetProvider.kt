package com.sahand.hava

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HavaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hava_widget).apply {
                setTextViewText(
                    R.id.widget_city,
                    widgetData.getString("city", "هوا") ?: "هوا"
                )
                setTextViewText(
                    R.id.widget_temperature,
                    widgetData.getString("temperature", "—") ?: "—"
                )
                setTextViewText(
                    R.id.widget_condition,
                    widgetData.getString("condition", "برای بروزرسانی برنامه را باز کنید")
                        ?: "برای بروزرسانی برنامه را باز کنید"
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
