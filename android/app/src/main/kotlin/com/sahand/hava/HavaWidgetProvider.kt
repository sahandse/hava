package com.sahand.hava

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

private fun bindBase(
    context: Context,
    layoutId: Int,
    widgetData: SharedPreferences
): RemoteViews = RemoteViews(context.packageName, layoutId).apply {
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

class HavaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(
                widgetId,
                bindBase(context, R.layout.hava_widget, widgetData)
            )
        }
    }
}

class HavaMediumWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = bindBase(context, R.layout.hava_widget_medium, widgetData).apply {
                setTextViewText(
                    R.id.widget_high_low,
                    "↑ " + (widgetData.getString("max_temp", "—") ?: "—") +
                        "   ↓ " + (widgetData.getString("min_temp", "—") ?: "—")
                )
                setTextViewText(
                    R.id.widget_rain,
                    "بارش " + (widgetData.getString("rain", "—") ?: "—")
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class HavaLargeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = bindBase(context, R.layout.hava_widget_large, widgetData).apply {
                setTextViewText(
                    R.id.widget_high_low,
                    "بیشینه " + (widgetData.getString("max_temp", "—") ?: "—") +
                        "   •   کمینه " + (widgetData.getString("min_temp", "—") ?: "—")
                )
                setTextViewText(
                    R.id.widget_rain,
                    "احتمال بارش " + (widgetData.getString("rain", "—") ?: "—")
                )
                setTextViewText(
                    R.id.widget_summary,
                    widgetData.getString("summary", "خلاصه امروز در برنامه نمایش داده می‌شود")
                        ?: "خلاصه امروز در برنامه نمایش داده می‌شود"
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
