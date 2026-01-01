package com.apkvideo.video_editor

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log
import java.io.File
import java.nio.ByteBuffer

/**
 * 使用 Android MediaMuxer API 进行视频裁剪
 * 无需依赖 FFmpeg，使用设备原生能力
 */
class VideoTrimmer {
    companion object {
        private const val TAG = "VideoTrimmer"
        private const val BUFFER_SIZE = 1024 * 1024  // 1MB buffer
        
        /**
         * 裁剪视频
         * @param inputPath 输入视频路径
         * @param outputPath 输出视频路径
         * @param startMs 开始时间（毫秒）
         * @param endMs 结束时间（毫秒）
         * @param callback 进度回调 (progress: 0-100)
         * @return 成功返回 true
         */
        fun trimVideo(
            inputPath: String,
            outputPath: String,
            startMs: Long,
            endMs: Long,
            callback: ((Int) -> Unit)? = null
        ): Boolean {
            var extractor: MediaExtractor? = null
            var muxer: MediaMuxer? = null
            
            try {
                // 删除已存在的输出文件
                File(outputPath).delete()
                
                extractor = MediaExtractor()
                extractor.setDataSource(inputPath)
                
                val trackCount = extractor.trackCount
                muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
                
                // 保存轨道索引映射
                val indexMap = HashMap<Int, Int>()
                
                // 添加所有轨道
                for (i in 0 until trackCount) {
                    val format = extractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                    
                    if (mime.startsWith("video/") || mime.startsWith("audio/")) {
                        val dstIndex = muxer.addTrack(format)
                        indexMap[i] = dstIndex
                    }
                }
                
                if (indexMap.isEmpty()) {
                    Log.e(TAG, "No video/audio tracks found")
                    return false
                }
                
                muxer.start()
                
                val buffer = ByteBuffer.allocate(BUFFER_SIZE)
                val bufferInfo = MediaCodec.BufferInfo()
                
                val startUs = startMs * 1000L
                val endUs = endMs * 1000L
                val durationUs = endUs - startUs
                
                // 处理每个轨道
                for ((srcIndex, dstIndex) in indexMap) {
                    extractor.selectTrack(srcIndex)
                    extractor.seekTo(startUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
                    
                    while (true) {
                        val sampleSize = extractor.readSampleData(buffer, 0)
                        if (sampleSize < 0) break
                        
                        val sampleTime = extractor.sampleTime
                        if (sampleTime > endUs) break
                        
                        if (sampleTime >= startUs) {
                            bufferInfo.offset = 0
                            bufferInfo.size = sampleSize
                            bufferInfo.presentationTimeUs = sampleTime - startUs
                            bufferInfo.flags = extractor.sampleFlags
                            
                            muxer.writeSampleData(dstIndex, buffer, bufferInfo)
                            
                            // 更新进度
                            val progress = ((sampleTime - startUs) * 100 / durationUs).toInt()
                            callback?.invoke(progress.coerceIn(0, 100))
                        }
                        
                        extractor.advance()
                    }
                    
                    extractor.unselectTrack(srcIndex)
                }
                
                callback?.invoke(100)
                Log.d(TAG, "Video trimmed successfully: $outputPath")
                return true
                
            } catch (e: Exception) {
                Log.e(TAG, "Error trimming video: ${e.message}", e)
                File(outputPath).delete()
                return false
            } finally {
                try {
                    muxer?.stop()
                    muxer?.release()
                } catch (e: Exception) {
                    Log.e(TAG, "Error releasing muxer", e)
                }
                extractor?.release()
            }
        }
    }
}
