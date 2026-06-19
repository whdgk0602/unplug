package com.example.project001

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.unplug.app/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareToInstagramStory" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath == null) {
                        result.success(false)
                    } else {
                        result.success(shareToInstagramStory(imagePath))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareToInstagramStory(imagePath: String): Boolean {
        val file = File(imagePath)
        if (!file.exists()) return false

        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )

        val intent = Intent("com.instagram.share.ADD_TO_STORY")
        intent.setDataAndType(uri, "image/*")
        intent.putExtra("source_application", packageName)
        intent.setPackage("com.instagram.android")
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

        return if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
            true
        } else {
            false
        }
    }
}
