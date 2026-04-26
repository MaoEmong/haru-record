package com.example.projectapp_1

import com.example.projectapp_1.tracking.TrackingMethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        TrackingMethodChannel(this).register(flutterEngine)
    }
}
