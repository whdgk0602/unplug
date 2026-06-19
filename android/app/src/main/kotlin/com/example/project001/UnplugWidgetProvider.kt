package com.example.project001

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class UnplugWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.unplug_widget).apply {
                val stage = widgetData.getInt("stage", 1).coerceIn(1, 12)
                val stageLabel = widgetData.getString("stageLabel", "Lv.1 모래섬")
                val unusedText = widgetData.getString("unusedText", "오늘 0분 절약")
                val resourceText = widgetData.getString("resourceText", "🌱 +0")

                val imageRes = context.resources.getIdentifier(
                    "island_stage_" + stage.toString().padStart(2, '0'),
                    "drawable",
                    context.packageName
                )
                if (imageRes != 0) {
                    setImageViewResource(R.id.widget_island_image, imageRes)
                }
                setTextViewText(R.id.widget_stage_label, stageLabel)
                setTextViewText(R.id.widget_unused_text, unusedText)
                setTextViewText(R.id.widget_resource_text, resourceText)
                setOnClickPendingIntent(R.id.widget_island_image, pendingIntent)
                setOnClickPendingIntent(R.id.widget_unused_text, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
