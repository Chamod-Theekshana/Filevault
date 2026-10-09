package com.filevault.app

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.EOFException
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.nio.ByteBuffer
import java.security.SecureRandom
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Native AES-256-GCM engine for the Secure Folder.
 *
 * Writes and reads exactly the same `.fv` format as the Dart engine
 * (`VaultCryptoService`):
 *
 * ```
 * magic "FVLT" | version u8 | chunkSize u32 | noncePrefix[8] | plainSize u64
 * then for every chunk i: ciphertext(chunk) || tag(16)
 * ```
 *
 * Chunk i uses nonce = prefix || i (big-endian u32) and authenticates
 * header || i || lastFlag as associated data, so chunks cannot be reordered,
 * dropped or truncated. Using the platform cipher (BoringSSL / Conscrypt with
 * ARMv8 AES instructions) is what makes multi-gigabyte videos practical.
 */
class VaultCryptoChannel : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.filevault/crypto"
        private val MAGIC = byteArrayOf(0x46, 0x56, 0x4C, 0x54) // FVLT
        private const val VERSION: Byte = 1
        private const val HEADER_LENGTH = 25
        private const val TAG_LENGTH = 16
        private const val PROGRESS_INTERVAL_MS = 120L
        private const val MAX_CHUNK_SIZE = 64 * 1024 * 1024
    }

    private class CancelledException : Exception()
    private class FormatException(message: String) : Exception(message)

    private var channel: MethodChannel? = null
    private val executor = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val cancelFlags = ConcurrentHashMap<String, AtomicBoolean>()
    private val random = SecureRandom()

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply { setMethodCallHandler(this@VaultCryptoChannel) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        cancelFlags.values.forEach { it.set(true) }
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "encryptFile", "decryptFile" -> {
                val jobId = call.argument<String>("jobId")
                val source = call.argument<String>("source")
                val destination = call.argument<String>("destination")
                val key = call.argument<ByteArray>("key")
                if (jobId == null || source == null || destination == null || key == null || key.size != 32) {
                    result.error("ARG", "jobId, source, destination and a 32-byte key are required", null)
                    return
                }
                val chunkSize = (call.argument<Int>("chunkSize") ?: (4 * 1024 * 1024))
                    .coerceIn(64 * 1024, MAX_CHUNK_SIZE)
                val flag = AtomicBoolean(false)
                cancelFlags[jobId] = flag
                val isEncrypt = call.method == "encryptFile"
                executor.execute {
                    try {
                        if (isEncrypt) {
                            encrypt(jobId, source, destination, key, chunkSize, flag)
                        } else {
                            decrypt(jobId, source, destination, key, flag)
                        }
                        mainHandler.post { result.success(null) }
                    } catch (error: Throwable) {
                        File(destination).delete()
                        val code = when (error) {
                            is CancelledException -> "CANCELLED"
                            is AEADBadTagException -> "INTEGRITY"
                            is FormatException -> "FORMAT"
                            is FileNotFoundException -> if (File(source).exists()) "PERMISSION" else "NOT_FOUND"
                            is SecurityException -> "PERMISSION"
                            is IOException -> if (isNoSpace(error)) "NO_SPACE" else "IO"
                            else -> "IO"
                        }
                        mainHandler.post { result.error(code, error.message ?: code, null) }
                    } finally {
                        cancelFlags.remove(jobId)
                        key.fill(0)
                    }
                }
            }
            "cancel" -> {
                val jobId = call.argument<String>("jobId")
                if (jobId != null) cancelFlags[jobId]?.set(true)
                result.success(null)
            }
            "isSupported" -> result.success(true)
            else -> result.notImplemented()
        }
    }

    // ------------------------------------------------------------- encrypt

    private fun encrypt(
        jobId: String,
        sourcePath: String,
        destinationPath: String,
        key: ByteArray,
        chunkSize: Int,
        cancelled: AtomicBoolean,
    ) {
        val source = File(sourcePath)
        if (!source.exists()) throw FileNotFoundException(sourcePath)
        val total = source.length()
        val prefix = ByteArray(8).also { random.nextBytes(it) }
        val header = buildHeader(chunkSize, prefix, total)
        val keySpec = SecretKeySpec(key, "AES")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val chunks = if (total == 0L) 1L else (total + chunkSize - 1) / chunkSize
        val buffer = ByteArray(chunkSize)
        val reporter = ProgressReporter(jobId, total)

        BufferedInputStream(FileInputStream(source), 1 shl 20).use { input ->
            FileOutputStream(destinationPath).use { fileOut ->
                BufferedOutputStream(fileOut, 1 shl 20).use { output ->
                    output.write(header)
                    var done = 0L
                    var index = 0L
                    while (index < chunks) {
                        if (cancelled.get()) throw CancelledException()
                        val last = index == chunks - 1
                        val want = if (last) (total - index * chunkSize).toInt() else chunkSize
                        readFully(input, buffer, want)
                        cipher.init(
                            Cipher.ENCRYPT_MODE,
                            keySpec,
                            GCMParameterSpec(TAG_LENGTH * 8, nonce(prefix, index.toInt())),
                        )
                        cipher.updateAAD(aad(header, index.toInt(), last))
                        output.write(cipher.doFinal(buffer, 0, want))
                        done += want
                        reporter.report(done)
                        index++
                    }
                    output.flush()
                    fileOut.fd.sync()
                }
            }
        }
        reporter.finish()
    }

    // ------------------------------------------------------------- decrypt

    private fun decrypt(
        jobId: String,
        sourcePath: String,
        destinationPath: String,
        key: ByteArray,
        cancelled: AtomicBoolean,
    ) {
        val source = File(sourcePath)
        if (!source.exists()) throw FileNotFoundException(sourcePath)
        BufferedInputStream(FileInputStream(source), 1 shl 20).use { input ->
            val header = ByteArray(HEADER_LENGTH)
            try {
                readFully(input, header, HEADER_LENGTH)
            } catch (error: EOFException) {
                throw FormatException("Not a FileVault encrypted file")
            }
            for (i in 0 until 4) {
                if (header[i] != MAGIC[i]) throw FormatException("Not a FileVault encrypted file")
            }
            if (header[4] != VERSION) throw FormatException("Unsupported FileVault format version")
            val view = ByteBuffer.wrap(header)
            val chunkSize = view.getInt(5)
            if (chunkSize <= 0 || chunkSize > MAX_CHUNK_SIZE) throw FormatException("Corrupt header")
            val prefix = header.copyOfRange(9, 17)
            val total = view.getLong(17)
            if (total < 0) throw FormatException("Corrupt header")
            val chunks = if (total == 0L) 1L else (total + chunkSize - 1) / chunkSize
            val keySpec = SecretKeySpec(key, "AES")
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val buffer = ByteArray(chunkSize + TAG_LENGTH)
            val reporter = ProgressReporter(jobId, total)

            FileOutputStream(destinationPath).use { fileOut ->
                BufferedOutputStream(fileOut, 1 shl 20).use { output ->
                    var done = 0L
                    var index = 0L
                    while (index < chunks) {
                        if (cancelled.get()) throw CancelledException()
                        val last = index == chunks - 1
                        val plainLength = if (last) (total - index * chunkSize).toInt() else chunkSize
                        try {
                            readFully(input, buffer, plainLength + TAG_LENGTH)
                        } catch (error: EOFException) {
                            throw FormatException("Encrypted file is truncated")
                        }
                        cipher.init(
                            Cipher.DECRYPT_MODE,
                            keySpec,
                            GCMParameterSpec(TAG_LENGTH * 8, nonce(prefix, index.toInt())),
                        )
                        cipher.updateAAD(aad(header, index.toInt(), last))
                        output.write(cipher.doFinal(buffer, 0, plainLength + TAG_LENGTH))
                        done += plainLength
                        reporter.report(done)
                        index++
                    }
                    output.flush()
                    fileOut.fd.sync()
                }
            }
            reporter.finish()
        }
    }

    // ------------------------------------------------------------- helpers

    private fun buildHeader(chunkSize: Int, prefix: ByteArray, total: Long): ByteArray {
        val buffer = ByteBuffer.allocate(HEADER_LENGTH) // big-endian, like Dart's ByteData
        buffer.put(MAGIC)
        buffer.put(VERSION)
        buffer.putInt(chunkSize)
        buffer.put(prefix)
        buffer.putLong(total)
        return buffer.array()
    }

    private fun nonce(prefix: ByteArray, index: Int): ByteArray {
        val buffer = ByteBuffer.allocate(12)
        buffer.put(prefix)
        buffer.putInt(index)
        return buffer.array()
    }

    private fun aad(header: ByteArray, index: Int, last: Boolean): ByteArray {
        val buffer = ByteBuffer.allocate(HEADER_LENGTH + 5)
        buffer.put(header)
        buffer.putInt(index)
        buffer.put(if (last) 1.toByte() else 0.toByte())
        return buffer.array()
    }

    private fun readFully(input: InputStream, target: ByteArray, length: Int) {
        var offset = 0
        while (offset < length) {
            val read = input.read(target, offset, length - offset)
            if (read < 0) throw EOFException("Unexpected end of file")
            offset += read
        }
    }

    private fun isNoSpace(error: IOException): Boolean {
        val message = error.message?.lowercase() ?: return false
        return message.contains("enospc") || message.contains("no space")
    }

    /** Throttled progress events back to Dart (main thread only). */
    private inner class ProgressReporter(private val jobId: String, private val total: Long) {
        private var lastSent = 0L

        fun report(done: Long) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastSent < PROGRESS_INTERVAL_MS) return
            lastSent = now
            send(done)
        }

        fun finish() = send(total)

        private fun send(done: Long) {
            val args = mapOf("jobId" to jobId, "done" to done, "total" to total)
            mainHandler.post { channel?.invokeMethod("progress", args) }
        }
    }
}
