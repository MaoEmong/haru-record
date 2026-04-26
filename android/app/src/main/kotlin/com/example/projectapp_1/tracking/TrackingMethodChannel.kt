package com.example.projectapp_1.tracking

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class TrackingMethodChannel(private val context: Context) {
    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "daily_pattern/tracking"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTracking" -> {
                    val movement = call.argument<Int>("minimumMovementMeters") ?: 100
                    val stay = call.argument<Int>("minimumStayMinutes") ?: 10
                    val intent = Intent(context, LocationTrackingService::class.java)
                        .putExtra("minimumMovementMeters", movement)
                        .putExtra("minimumStayMinutes", stay)
                    ContextCompat.startForegroundService(context, intent)
                    result.success(null)
                }
                "stopTracking" -> {
                    context.stopService(Intent(context, LocationTrackingService::class.java))
                    result.success(null)
                }
                "isTracking" -> result.success(LocationTrackingService.isRunning)
                "getEventFilePath" -> {
                    result.success(LocationTrackingService.eventFile(context).absolutePath)
                }
                else -> result.notImplemented()
            }
        }
    }
}
