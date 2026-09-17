package com.kraftech.muslim_launcher_2

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log

/**
 * Transparent helper activity dedicated to requesting Device Admin activation.
 *
 * Why this is necessary:
 * MainActivity uses launchMode="singleTask" and clearTaskOnLaunch="true" as an Android HOME launcher.
 * Starting DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN with FLAG_ACTIVITY_NEW_TASK is explicitly
 * rejected by Android's DeviceAdminAdd (which immediately logs "Cannot start ADD_DEVICE_ADMIN as a new task"
 * and calls finish()).
 *
 * Conversely, starting it from a singleTask activity without NEW_TASK can cause stack interference.
 * This standard-launchMode translucent activity provides an isolated task context to launch
 * ACTION_ADD_DEVICE_ADMIN via startActivityForResult cleanly across all Android versions & OEMs (Xiaomi, Samsung, Oppo, etc.).
 */
class DeviceAdminRequestActivity : Activity() {

    companion object {
        private const val TAG = "DeviceAdminRequest"
        private const val REQUEST_CODE_ENABLE_ADMIN = 1001

        fun start(context: Context) {
            val intent = Intent(context, DeviceAdminRequestActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Arm the 90s bypass window in AppBlockService
        AppBlockService.allowDeviceAdminActivationTemporarily()
        try {
            val broadcastIntent = Intent("com.muslimlauncher.BYPASS_DEVICE_ADMIN_ACTIVATION").apply {
                setPackage(packageName)
            }
            sendBroadcast(broadcastIntent)
        } catch (_: Exception) {}

        // 2. Check if already active
        if (AppBlockService.isDeviceAdminActive(this)) {
            Log.d(TAG, "Device Admin already active, finishing immediately")
            finish()
            return
        }

        // 3. Launch system Device Admin activation screen
        val component = ComponentName(this, MuslimDeviceAdminReceiver::class.java)
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, component)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "Mengaktifkan Administrator Perangkat untuk mencegah pencopotan aplikasi selama Mode Ketat (Komitmen Istiqomah) berjalan."
            )
        }

        try {
            startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
        } catch (e: Exception) {
            Log.e(TAG, "startActivityForResult failed: ${e.message}, falling back to security settings")
            try {
                startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
            } catch (_: Exception) {}
            finish()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            val isActive = AppBlockService.isDeviceAdminActive(this)
            Log.d(TAG, "onActivityResult: resultCode=$resultCode, isActive=$isActive")
            if (isActive) {
                AppBlockService.deviceAdminActivationBypassUntil = 0L
            }
        }
        finish()
    }
}
