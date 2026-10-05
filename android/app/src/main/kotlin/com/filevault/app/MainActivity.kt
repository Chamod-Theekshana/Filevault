package com.filevault.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hosts the Flutter UI and registers FileVault's platform channel.
 *
 * Extends [FlutterFragmentActivity] because the biometric prompt used to
 * unlock the Secure Folder (local_auth) requires a FragmentActivity host.
 */
class MainActivity : FlutterFragmentActivity() {

    private var channel: FileVaultChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = FileVaultChannel(this).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onDestroy() {
        channel?.detach()
        channel = null
        super.onDestroy()
    }
}
