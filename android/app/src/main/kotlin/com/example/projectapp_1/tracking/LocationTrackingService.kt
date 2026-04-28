package com.example.projectapp_1.tracking

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import java.io.File
import java.time.Instant
import org.json.JSONObject

class LocationTrackingService : Service() {
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.locations.forEach(::recordLocation)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val rawLocationIntervalSeconds =
            intent?.getIntExtra("rawLocationIntervalSeconds", 10) ?: 10

        if (!hasLocationPermission()) {
            logTrackingStopped("missing_location_permission")
            stopSelf()
            return START_NOT_STICKY
        }

        try {
            startForeground(FOREGROUND_NOTIFICATION_ID, buildNotification())
        } catch (exception: SecurityException) {
            logTrackingStopped("foreground_service_permission_denied")
            stopSelf()
            return START_NOT_STICKY
        }

        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            rawLocationIntervalMillis(rawLocationIntervalSeconds)
        )
            .setMinUpdateIntervalMillis(MIN_RAW_LOCATION_INTERVAL_MILLIS)
            .build()

        try {
            fusedLocationClient.requestLocationUpdates(request, locationCallback, mainLooper)
                .addOnSuccessListener {
                    isRunning = true
                }
                .addOnFailureListener {
                    logTrackingStopped("location_updates_failed")
                    stopSelf()
                }
        } catch (exception: SecurityException) {
            logTrackingStopped("location_updates_permission_denied")
            stopSelf()
            return START_NOT_STICKY
        }

        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        if (::fusedLocationClient.isInitialized && ::locationCallback.isInitialized) {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        }
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun hasLocationPermission(): Boolean {
        val fine = ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "하루 기록",
                NotificationManager.IMPORTANCE_LOW
            )
            manager.createNotificationChannel(channel)
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("하루 기록")
            .setContentText("오늘의 흐름을 조용히 남기고 있어요")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .build()
    }

    private fun recordLocation(location: Location) {
        val event = JSONObject()
            .put("event", "location_recorded")
            .put("timestamp", Instant.ofEpochMilli(location.time).toString())
            .put("latitude", location.latitude)
            .put("longitude", location.longitude)
            .put("accuracy", location.accuracy.toDouble())
            .put("speed", if (location.hasSpeed()) location.speed.toDouble() else JSONObject.NULL)
            .put("isMock", isMockLocation(location))
            .put("source", "android")

        eventFile(this).appendText(event.toString() + "\n")
        Log.d(LOG_TAG, redactedLocationLog(location).toString())
    }

    private fun logTrackingStopped(reason: String) {
        Log.w(
            LOG_TAG,
            JSONObject()
                .put("event", "tracking_stopped")
                .put("reason", reason)
                .toString()
        )
    }

    private fun redactedLocationLog(location: Location): JSONObject {
        return JSONObject()
            .put("event", "location_recorded")
            .put("accuracy", location.accuracy.toDouble())
            .put("hasSpeed", location.hasSpeed())
            .put("isMock", isMockLocation(location))
            .put("source", "android")
    }

    private fun isMockLocation(location: Location): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            location.isMock
        } else {
            @Suppress("DEPRECATION")
            location.isFromMockProvider
        }
    }

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "daily_pattern_tracking"
        const val FOREGROUND_NOTIFICATION_ID = 1001
        private const val DEFAULT_RAW_LOCATION_INTERVAL_MILLIS = 10 * 1000L
        private const val MIN_RAW_LOCATION_INTERVAL_MILLIS = 5 * 1000L
        private const val MAX_RAW_LOCATION_INTERVAL_MILLIS = 10 * 1000L
        private const val LOG_TAG = "DailyPatternTracking"

        @Volatile
        var isRunning: Boolean = false
            private set

        fun eventFile(context: Context): File = File(context.filesDir, "location_events.jsonl")

        private fun rawLocationIntervalMillis(rawLocationIntervalSeconds: Int): Long {
            val requestedMillis = rawLocationIntervalSeconds.coerceAtLeast(1) * 1000L
            return requestedMillis.coerceIn(
                MIN_RAW_LOCATION_INTERVAL_MILLIS,
                MAX_RAW_LOCATION_INTERVAL_MILLIS
            ).takeIf { it > 0 } ?: DEFAULT_RAW_LOCATION_INTERVAL_MILLIS
        }
    }
}
