package com.filevault.app

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.media.MediaMetadataRetriever
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

/**
 * Platform channel backing [PlatformChannelService] on the Dart side:
 * storage volumes, video thumbnails, APK metadata, the media scanner and the
 * foreground-service notification for long file operations.
 */
class FileVaultChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.filevault/platform"
    }

    private var channel: MethodChannel? = null
    private val executor = Executors.newFixedThreadPool(2)

    /** Media-index work gets its own thread so it never delays thumbnails. */
    private val mediaExecutor = Executors.newSingleThreadExecutor()

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply { setMethodCallHandler(this@FileVaultChannel) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        executor.shutdownNow()
        mediaExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStorageVolumes" -> result.success(storageVolumes())
            "getVideoThumbnail" -> {
                val path = call.argument<String>("path")
                val width = call.argument<Int>("width") ?: 320
                if (path == null) {
                    result.error("ARG", "path is required", null)
                } else {
                    runAsync(result) { videoThumbnail(path, width) }
                }
            }
            "getApkInfo" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("ARG", "path is required", null)
                } else {
                    runAsync(result) { apkInfo(path) }
                }
            }
            "scanMedia" -> {
                val paths = call.argument<List<String>>("paths").orEmpty()
                MediaScannerConnection.scanFile(context, paths.toTypedArray(), null, null)
                result.success(null)
            }
            "syncMedia" -> {
                val added = call.argument<List<String>>("added").orEmpty()
                val removed = call.argument<List<String>>("removed").orEmpty()
                mediaExecutor.execute {
                    try {
                        syncMedia(added, removed)
                    } catch (ignored: Throwable) {
                    }
                }
                result.success(null)
            }
            "setSecureWindow" -> {
                val secure = call.argument<Boolean>("secure") ?: false
                val window = (context as? Activity)?.window
                if (window != null) {
                    if (secure) {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE,
                        )
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                }
                result.success(null)
            }
            "startOperationService" -> {
                OperationService.start(
                    context,
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("text").orEmpty(),
                    call.argument<Int>("progress") ?: 0,
                )
                result.success(null)
            }
            "updateOperationService" -> {
                OperationService.update(
                    context,
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("text").orEmpty(),
                    call.argument<Int>("progress") ?: 0,
                )
                result.success(null)
            }
            "finishOperationService" -> {
                OperationService.finish(
                    context,
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("text").orEmpty(),
                )
                result.success(null)
            }
            "stopOperationService" -> {
                OperationService.stop(context)
                result.success(null)
            }
            "openAllFilesAccessSettings" -> {
                openAllFilesAccessSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun <T> runAsync(result: MethodChannel.Result, body: () -> T) {
        executor.execute {
            val value = try {
                body()
            } catch (error: Throwable) {
                null
            }
            android.os.Handler(context.mainLooper).post { result.success(value) }
        }
    }

    // --------------------------------------------------------------- media

    /**
     * Keeps MediaStore consistent after file operations.
     *
     * Rows are only deleted for paths that no longer exist: on Android 11+
     * deleting a MediaStore row also deletes its file, so this check is what
     * makes the call safe. Rows below a removed folder are dropped too. New
     * paths are handed to the media scanner so galleries pick them up.
     */
    private fun syncMedia(added: List<String>, removed: List<String>) {
        val resolver = context.contentResolver
        val filesUri = MediaStore.Files.getContentUri("external")
        val rescan = mutableListOf<String>()
        for (path in removed) {
            if (File(path).exists()) continue
            val escaped = path.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
            try {
                @Suppress("DEPRECATION")
                resolver.delete(
                    filesUri,
                    "${MediaStore.MediaColumns.DATA} = ? OR ${MediaStore.MediaColumns.DATA} LIKE ? ESCAPE '\\'",
                    arrayOf(path, "$escaped/%"),
                )
            } catch (error: Throwable) {
                // Not allowed without all-files access – fall back to a scan,
                // which drops rows of missing files on most Android versions.
            }
            rescan.add(path)
        }
        rescan.addAll(added)
        if (rescan.isNotEmpty()) {
            rescan.chunked(500).forEach { batch ->
                MediaScannerConnection.scanFile(context, batch.toTypedArray(), null, null)
            }
        }
    }

    // ------------------------------------------------------------- volumes

    private fun storageVolumes(): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        val manager = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && manager != null) {
            for (volume in manager.storageVolumes) {
                val directory = volumeDirectory(volume) ?: continue
                if (!directory.exists()) continue
                val stat = statOf(directory) ?: continue
                val removable = volume.isRemovable
                val primary = volume.isPrimary
                out.add(
                    mapOf(
                        "id" to (volume.uuid ?: directory.absolutePath),
                        "name" to (volume.getDescription(context) ?: directory.name),
                        "path" to directory.absolutePath,
                        "totalBytes" to stat.first,
                        "freeBytes" to stat.second,
                        "isPrimary" to primary,
                        "isRemovable" to removable,
                        "kind" to when {
                            primary || !removable -> "internal"
                            isUsb(directory) -> "usb"
                            else -> "sdCard"
                        },
                    )
                )
            }
        }

        if (out.isEmpty()) {
            val external = Environment.getExternalStorageDirectory()
            val stat = statOf(external)
            out.add(
                mapOf(
                    "id" to "internal",
                    "name" to "Internal storage",
                    "path" to external.absolutePath,
                    "totalBytes" to (stat?.first ?: 0L),
                    "freeBytes" to (stat?.second ?: 0L),
                    "isPrimary" to true,
                    "isRemovable" to false,
                    "kind" to "internal",
                )
            )
            // Secondary volumes exposed through getExternalFilesDirs.
            context.getExternalFilesDirs(null)
                .filterNotNull()
                .drop(1)
                .forEach { appDir ->
                    val root = rootOf(appDir)
                    val s = statOf(root) ?: return@forEach
                    out.add(
                        mapOf(
                            "id" to root.name,
                            "name" to "SD card",
                            "path" to root.absolutePath,
                            "totalBytes" to s.first,
                            "freeBytes" to s.second,
                            "isPrimary" to false,
                            "isRemovable" to true,
                            "kind" to if (isUsb(root)) "usb" else "sdCard",
                        )
                    )
                }
        }
        return out
    }

    @SuppressLint("DiscouragedPrivateApi")
    @RequiresApi(Build.VERSION_CODES.N)
    private fun volumeDirectory(volume: StorageVolume): File? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return volume.directory
        }
        return try {
            val method = StorageVolume::class.java.getDeclaredMethod("getPath")
            val path = method.invoke(volume) as? String
            path?.let { File(it) }
        } catch (error: Throwable) {
            null
        }
    }

    /** Strips "/Android/data/<pkg>/files" to get the volume root. */
    private fun rootOf(appDir: File): File {
        val marker = "/Android/data/"
        val path = appDir.absolutePath
        val index = path.indexOf(marker)
        return if (index > 0) File(path.substring(0, index)) else appDir
    }

    private fun isUsb(directory: File): Boolean {
        val lower = directory.absolutePath.lowercase()
        return lower.contains("usb") || lower.contains("otg")
    }

    /** Returns (totalBytes, freeBytes) or null when the path is unreadable. */
    private fun statOf(directory: File): Pair<Long, Long>? {
        return try {
            val stat = StatFs(directory.absolutePath)
            Pair(stat.blockCountLong * stat.blockSizeLong, stat.availableBlocksLong * stat.blockSizeLong)
        } catch (error: Throwable) {
            null
        }
    }

    // ---------------------------------------------------------- thumbnails

    private fun videoThumbnail(path: String, width: Int): ByteArray? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            val frame = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                retriever.getScaledFrameAtTime(
                    -1,
                    MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                    width,
                    width,
                )
            } else {
                retriever.getFrameAtTime(-1, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            } ?: return null
            ByteArrayOutputStream().use { stream ->
                frame.compress(Bitmap.CompressFormat.JPEG, 80, stream)
                stream.toByteArray()
            }
        } catch (error: Throwable) {
            null
        } finally {
            try {
                retriever.release()
            } catch (ignored: Throwable) {
            }
        }
    }

    // ------------------------------------------------------------- apk info

    private fun apkInfo(path: String): Map<String, Any?>? {
        val pm = context.packageManager
        val flags = PackageManager.GET_PERMISSIONS
        val info: PackageInfo = pm.getPackageArchiveInfo(path, flags) ?: return null
        val appInfo: ApplicationInfo = info.applicationInfo ?: return null
        appInfo.sourceDir = path
        appInfo.publicSourceDir = path

        val installed = try {
            pm.getPackageInfo(info.packageName, 0)
        } catch (error: PackageManager.NameNotFoundException) {
            null
        }

        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }

        return mapOf(
            "packageName" to info.packageName,
            "appName" to pm.getApplicationLabel(appInfo).toString(),
            "versionName" to (info.versionName ?: ""),
            "versionCode" to versionCode,
            "minSdk" to appInfo.minSdkVersion,
            "targetSdk" to appInfo.targetSdkVersion,
            "icon" to drawableToPng(pm.getApplicationIcon(appInfo)),
            "permissions" to (info.requestedPermissions?.toList() ?: emptyList<String>()),
            "isInstalled" to (installed != null),
            "installedVersionName" to installed?.versionName,
        )
    }

    private fun drawableToPng(drawable: Drawable?): ByteArray? {
        if (drawable == null) return null
        return try {
            val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
                drawable.bitmap
            } else {
                val size = 144
                val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(output)
                drawable.setBounds(0, 0, size, size)
                drawable.draw(canvas)
                output
            }
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                stream.toByteArray()
            }
        } catch (error: Throwable) {
            null
        }
    }

    // -------------------------------------------------------------- settings

    private fun openAllFilesAccessSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                data = Uri.parse("package:${context.packageName}")
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
            }
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (error: Throwable) {
            val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(fallback)
        }
    }
}
