package com.maoemong.harurecord

import com.maoemong.harurecord.tracking.TrackingMethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        TrackingMethodChannel(this).register(flutterEngine)
    }
}
