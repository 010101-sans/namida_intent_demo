package com.example.namida_intent_demo

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.namida_intent_demo/intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchNamidaSync") {
                val backupPath = call.argument<String>("backupPath")
                val musicFolders = call.argument<String>("musicFolders")
                try {
                    val intent = Intent()
                    intent.setClassName("com.sanskar.namidasync", "com.sanskar.namidasync.MainActivity")
                    intent.action = Intent.ACTION_MAIN
                    intent.putExtra("backupPath", backupPath)
                    intent.putExtra("musicFolders", musicFolders)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("LAUNCH_FAILED", "Could not launch Namida Sync: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
