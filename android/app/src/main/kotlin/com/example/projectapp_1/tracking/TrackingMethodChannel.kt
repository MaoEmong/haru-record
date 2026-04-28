package com.example.projectapp_1.tracking

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
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
                    val rawInterval = call.argument<Int>("rawLocationIntervalSeconds") ?: 10
                    if (!hasLocationPermission()) {
                        result.error(
                            "location_permission_missing",
                            "하루를 기록하려면 위치 권한이 필요해요.",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    val intent = Intent(context, LocationTrackingService::class.java)
                        .putExtra("minimumMovementMeters", movement)
                        .putExtra("minimumStayMinutes", stay)
                        .putExtra("rawLocationIntervalSeconds", rawInterval)
                    try {
                        ContextCompat.startForegroundService(context, intent)
                        result.success(null)
                    } catch (exception: RuntimeException) {
                        result.error(
                            "tracking_start_failed",
                            exception.message ?: "하루 기록을 시작하지 못했어요.",
                            null
                        )
                    }
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

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }
}
