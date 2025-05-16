package com.example.kolayara

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "direct_call_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "directCall") {
                val phone = call.argument<String>("phone")
                val intent = Intent(Intent.ACTION_CALL)
                intent.data = Uri.parse("tel:$phone")
                startActivity(intent)
                result.success(null)
            }
        }
    }
}
