package com.kraftech.muslim_launcher_2

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class MuslimDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d("MuslimDeviceAdmin", "Device Administrator Enabled for Muslim Launcher 2")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        try {
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            val isStrict = prefs.getBoolean("strict_mode_enabled", false)
            val strictUntil = prefs.getLong("strict_mode_until", 0L)
            val now = System.currentTimeMillis()

            if (isStrict && now < strictUntil) {
                val remainingDays = ((strictUntil - now) / (1000 * 60 * 60 * 24)).coerceAtLeast(1)
                return "Mode Ketat masih aktif (tersisa sekitar $remainingDays hari)! Deaktivasi dibatasi untuk menjaga komitmen istiqomah."
            }
        } catch (e: Exception) {
            Log.e("MuslimDeviceAdmin", "Error in onDisableRequested: ${e.message}")
        }
        return "Peringatan: Menonaktifkan administrator perangkat akan mematikan perlindungan komitmen aplikasi."
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d("MuslimDeviceAdmin", "Device Administrator Disabled for Muslim Launcher 2")
    }
}
