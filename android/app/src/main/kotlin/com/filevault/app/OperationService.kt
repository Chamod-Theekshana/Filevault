package com.filevault.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Foreground service that keeps long file operations (copy, move, extract,
 * encrypt) alive while the app is in the background and shows their progress
 * in a notification.
 */
class OperationService : Service() {

    companion object {
        private const val CHANNEL_ID = "filevault_operations"
        private const val DONE_CHANNEL_ID = "filevault_operations_done"
        private const val NOTIFICATION_ID = 4711
        private const val DONE_NOTIFICATION_ID = 4712

        private const val ACTION_START = "com.filevault.app.START"
        private const val ACTION_UPDATE = "com.filevault.app.UPDATE"
        private const val ACTION_FINISH = "com.filevault.app.FINISH"
        private const val ACTION_STOP = "com.filevault.app.STOP"

        fun start(context: Context, title: String, text: String, progress: Int) {
            send(context, ACTION_START, title, text, progress, startForeground = true)
        }

        fun update(context: Context, title: String, text: String, progress: Int) {
            send(context, ACTION_UPDATE, title, text, progress, startForeground = false)
        }

        fun finish(context: Context, title: String, text: String) {
            send(context, ACTION_FINISH, title, text, 100, startForeground = false)
        }

        fun stop(context: Context) {
            send(context, ACTION_STOP, "", "", 0, startForeground = false)
        }

        private fun send(
            context: Context,
            action: String,
            title: String,
            text: String,
            progress: Int,
            startForeground: Boolean,
        ) {
            val intent = Intent(context, OperationService::class.java).apply {
                this.action = action
                putExtra("title", title)
                putExtra("text", text)
                putExtra("progress", progress)
            }
            try {
                if (startForeground && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (error: Throwable) {
                // Starting a service can be refused in the background; the
                // operation itself keeps running inside the Dart isolate.
            }
        }
    }

    private var started = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_UPDATE
        val title = intent?.getStringExtra("title").orEmpty()
        val text = intent?.getStringExtra("text").orEmpty()
        val progress = intent?.getIntExtra("progress", 0) ?: 0

        when (action) {
            ACTION_START -> {
                startInForeground(buildProgress(title, text, progress))
            }
            ACTION_UPDATE -> {
                if (!started) {
                    startInForeground(buildProgress(title, text, progress))
                } else {
                    notify(NOTIFICATION_ID, buildProgress(title, text, progress))
                }
            }
            ACTION_FINISH -> {
                notify(DONE_NOTIFICATION_ID, buildDone(title, text))
                stopForegroundCompat()
            }
            ACTION_STOP -> stopForegroundCompat()
        }
        return START_NOT_STICKY
    }

    private fun startInForeground(notification: Notification) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            started = true
        } catch (error: Throwable) {
            started = false
        }
    }

    private fun stopForegroundCompat() {
        started = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun contentIntent(): PendingIntent? {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, 0, launch, flags)
    }

    private fun buildProgress(title: String, text: String, progress: Int): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title.ifEmpty { getString(applicationInfo.labelRes) })
            .setContentText(text)
            .setProgress(100, progress.coerceIn(0, 100), progress <= 0)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(contentIntent())
            .build()
    }

    private fun buildDone(title: String, text: String): Notification {
        return NotificationCompat.Builder(this, DONE_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(title.ifEmpty { getString(applicationInfo.labelRes) })
            .setContentText(text)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(contentIntent())
            .build()
    }

    private fun notify(id: Int, notification: Notification) {
        try {
            NotificationManagerCompat.from(this).notify(id, notification)
        } catch (error: SecurityException) {
            // POST_NOTIFICATIONS not granted on Android 13+.
        }
    }

    private fun createChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "File operations",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Progress of copy, move, compress and encrypt operations"
                setShowBadge(false)
            }
        )
        manager.createNotificationChannel(
            NotificationChannel(
                DONE_CHANNEL_ID,
                "Completed operations",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Notifies when a file operation finishes"
            }
        )
    }
}
