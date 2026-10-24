package com.fschmatz.podmatz

import android.util.Log

object WakeLockHelper {
    private const val TAG = "PodmatzWakeLock"

    fun releaseWakeLock() {
        try {
            val audioServiceClass = Class.forName("com.ryanheise.audioservice.AudioService")
            val instanceField = audioServiceClass.getDeclaredField("instance")
            instanceField.isAccessible = true
            val serviceInstance = instanceField.get(null) ?: run {
                Log.d(TAG, "AudioService instance is null, no wakelock to release")
                return
            }

            val releaseMethod = audioServiceClass.getDeclaredMethod("releaseWakeLock")
            releaseMethod.isAccessible = true
            releaseMethod.invoke(serviceInstance)
            Log.d(TAG, "AudioService.releaseWakeLock() invoked successfully")
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to release AudioService wakeLock: ${e.message}", e)
        }
    }

    fun acquireWakeLock() {
        try {
            val audioServiceClass = Class.forName("com.ryanheise.audioservice.AudioService")
            val instanceField = audioServiceClass.getDeclaredField("instance")
            instanceField.isAccessible = true
            val serviceInstance = instanceField.get(null) ?: run {
                Log.d(TAG, "AudioService instance is null, cannot acquire wakelock")
                return
            }

            val acquireMethod = audioServiceClass.getDeclaredMethod("acquireWakeLock")
            acquireMethod.isAccessible = true
            acquireMethod.invoke(serviceInstance)
            Log.d(TAG, "AudioService.acquireWakeLock() invoked successfully")
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to acquire AudioService wakeLock: ${e.message}", e)
        }
    }
}
