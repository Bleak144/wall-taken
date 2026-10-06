package com.example.wall_changer

import android.app.WallpaperManager
import android.content.Context
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class WallChangerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "wall_changer")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method != "setWallpaper") {
            result.notImplemented()
            return
        }
        val path = call.argument<String>("path")
        val target = call.argument<String>("target") ?: "both"
        if (path == null) {
            result.error("NO_PATH", "Falta la ruta", null)
            return
        }
        Thread {
            try {
                val bitmap = BitmapFactory.decodeFile(path)
                    ?: throw IllegalStateException("No se pudo leer la imagen")
                val flags = when (target) {
                    "home" -> WallpaperManager.FLAG_SYSTEM
                    "lock" -> WallpaperManager.FLAG_LOCK
                    else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                }
                WallpaperManager.getInstance(context).setBitmap(bitmap, null, true, flags)
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post { result.error("SET_FAILED", e.message, null) }
            }
        }.start()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}