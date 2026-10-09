package com.filevault.app

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter UI and registers FileVault's platform channels.
 *
 * Extends [AudioServiceFragmentActivity] because the biometric prompt used by the
 * App Lock and the Secure Folder (local_auth) requires a FragmentActivity,
 * and media playback notifications require AudioService support.
 */
class MainActivity : AudioServiceFragmentActivity() {

    private var channel: FileVaultChannel? = null
    private var crypto: VaultCryptoChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        channel = FileVaultChannel(this).also { it.attach(messenger) }
        crypto = VaultCryptoChannel().also { it.attach(messenger) }
    }

    override fun onDestroy() {
        channel?.detach()
        channel = null
        crypto?.detach()
        crypto = null
        super.onDestroy()
    }
}
