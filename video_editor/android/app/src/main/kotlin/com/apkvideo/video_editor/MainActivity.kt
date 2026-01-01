package com.apkvideo.video_editor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import android.os.Handler
import android.os.Looper

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.video_editor/trimmer"
    private val EVENT_CHANNEL = "com.example.video_editor/progress"
    
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 进度事件通道
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
        
        // 方法通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "trimVideo" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    val startMs = call.argument<Number>("startMs")?.toLong()
                    val endMs = call.argument<Number>("endMs")?.toLong()
                    
                    if (inputPath == null || outputPath == null || startMs == null || endMs == null) {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }
                    
                    // 在后台线程执行裁剪
                    scope.launch {
                        val success = VideoTrimmer.trimVideo(inputPath, outputPath, startMs, endMs) { progress ->
                            mainHandler.post {
                                eventSink?.success(progress)
                            }
                        }
                        
                        mainHandler.post {
                            if (success) {
                                result.success(outputPath)
                            } else {
                                result.error("TRIM_FAILED", "Failed to trim video", null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }
}
