package com.kraftech.muslim_launcher_2

import android.accessibilityservice.AccessibilityService
import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.ComponentName
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.os.Build
import android.content.IntentFilter
import android.os.Vibrator
import android.os.VibratorManager
import android.os.VibrationEffect
import java.util.concurrent.ConcurrentHashMap
import java.util.Collections

class AppBlockService : AccessibilityService() {
    companion object {
        private var instance: AppBlockService? = null
        private val handler = android.os.Handler(android.os.Looper.getMainLooper())
        private var blockedPackages = Collections.synchronizedSet(mutableSetOf<String>())
        private var temporaryAllowedPackages = ConcurrentHashMap<String, Long>()
        
        // Countdown vibration alert tracking (3m -> 3x, 2m -> 2x, final kick -> 1x long ending at exit)
        private val notified3Min = Collections.synchronizedSet(mutableSetOf<String>())
        private val notified2Min = Collections.synchronizedSet(mutableSetOf<String>())
        private val notified1Min = Collections.synchronizedSet(mutableSetOf<String>())
        private const val FINAL_VIBRATION_MS = 1200L
        
        // Ghadhul Bashar state tracking
        private var ghadhulBasharPackages = Collections.synchronizedSet(mutableSetOf<String>())
        private var activeGhadhulSessions = Collections.synchronizedSet(mutableSetOf<String>())
        private var lastActiveGhadhulTimes = ConcurrentHashMap<String, Long>()

        // Prohibited bypass browsers (Permanently blocked in restricted regions)
        private var prohibitedPackages = Collections.synchronizedSet(mutableSetOf<String>())

        // Strict Mode state tracking
        @Volatile
        private var isStrictModeEnabled: Boolean = false
        @Volatile
        private var strictModeUntil: Long = 0L
        @Volatile
        private var strictModeDays: Int = 30
        @Volatile
        private var lastKnownTimestamp: Long = 0L

        // Transition Shield: Prevent loop during the first 10 seconds of unlock
        private var lastBypassPackage: String? = null
        private var lastBypassTime: Long = 0
        private var currentForegroundPackage: String? = null

        // One-time bypass for opening Developer Support (Trakteer / Ko-fi) links
        @Volatile
        private var bypassSupportDeveloperUntil: Long = 0L

        // Standard Mode temporary bypass for accessing settings / play store after clicking "Lewati"
        @Volatile
        private var standardModeBypassExpiry: Long = 0L

        @Volatile
        var lastStandardReflectionSource: String = "settings"

        @Volatile
        var hasCompletedOnboarding: Boolean = false

        fun setOnboardingCompleted(context: Context, completed: Boolean) {
            hasCompletedOnboarding = completed
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("hasCompletedOnboarding", completed).apply()
            Log.d("AppBlockService", "ONBOARDING STATUS UPDATED: completed=$completed")
        }

        fun isOnboardingCompleted(context: Context): Boolean {
            if (hasCompletedOnboarding) return true
            try {
                val blockPrefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
                if (blockPrefs.getBoolean("hasCompletedOnboarding", false)) {
                    hasCompletedOnboarding = true
                    return true
                }
            } catch (_: Exception) {}
            try {
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                if (flutterPrefs.getBoolean("flutter.hasCompletedOnboarding", false)) {
                    hasCompletedOnboarding = true
                    return true
                }
            } catch (_: Exception) {}
            return false
        }

        @Volatile
        private var serviceConnectedTime: Long = 0L

        @Volatile
        private var lastBypassGrantTime: Long = 0L

        @Volatile
        private var hasEnteredBypassedScreen: Boolean = false

        fun allowStandardSettingsTemporarily(durationMillis: Long) {
            val now = System.currentTimeMillis()
            standardModeBypassExpiry = now + durationMillis
            lastBypassGrantTime = now
            hasEnteredBypassedScreen = false
            Log.d("AppBlockService", "STANDARD MODE SETTINGS BYPASS GRANTED until $standardModeBypassExpiry (visit active)")
        }

        fun resetStandardSettingsBypass(force: Boolean = false) {
            val now = System.currentTimeMillis()
            // 3.5s grace period immediately after clicking "Lewati" to protect screen launch transition
            if (!force && (now - lastBypassGrantTime) < 3500L) {
                return
            }
            standardModeBypassExpiry = 0L
            hasEnteredBypassedScreen = false
            lastTriggeredPackage = null
            lastTriggeredTime = 0L
            MainActivity.resetReflectionDebounce()
            Log.d("AppBlockService", "STANDARD SETTINGS BYPASS & DEBOUNCE RESET (session ended, force=$force)")
        }

        @Volatile
        var deviceAdminActivationBypassUntil: Long = 0L

        fun allowDeviceAdminActivationTemporarily() {
            deviceAdminActivationBypassUntil = System.currentTimeMillis() + 90000L
            Log.d("AppBlockService", "DEVICE ADMIN ACTIVATION BYPASS GRANTED (90s window)")
        }

        fun isDeviceAdminActive(context: Context?): Boolean {
            if (context == null) return false
            return try {
                val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? android.app.admin.DevicePolicyManager
                val component = ComponentName(context, MuslimDeviceAdminReceiver::class.java)
                dpm?.isAdminActive(component) == true
            } catch (_: Exception) {
                false
            }
        }

        fun prepareSupportDeveloperBypass() {
            bypassSupportDeveloperUntil = System.currentTimeMillis() + 10000L
            Log.d("AppBlockService", "SUPPORT DEVELOPER BYPASS ARMED (10s window)")
        }

        // Debounce to prevent multiple back-to-back startActivity calls on rapid accessibility events
        private var lastTriggeredPackage: String? = null
        private var lastTriggeredTime: Long = 0

        private val watchdogRunnable = object : Runnable {
            override fun run() {
                if (temporaryAllowedPackages.isNotEmpty()) {
                    checkCountdownVibrations()
                    checkAllExpiredUnlocks()
                    if (temporaryAllowedPackages.isNotEmpty()) {
                        handler.postDelayed(this, 1000L)
                    }
                }
            }
        }

        fun startWatchdog() {
            handler.removeCallbacks(watchdogRunnable)
            if (temporaryAllowedPackages.isNotEmpty()) {
                handler.post(watchdogRunnable)
            }
        }

        fun checkAndKickExpiredApp(packageName: String) {
            val s = instance ?: return
            val cleanPkg = packageName.trim().lowercase()
            val now = System.currentTimeMillis()
            val expiry = temporaryAllowedPackages[cleanPkg]
            if (expiry != null && now >= (expiry - 300L)) {
                temporaryAllowedPackages.remove(cleanPkg)
                notified3Min.remove(cleanPkg)
                notified2Min.remove(cleanPkg)
                notified1Min.remove(cleanPkg)
                
                // Remove from SharedPreferences
                try {
                    val prefs = s.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
                    val allowedMap = (prefs.getStringSet("allowed_temp_packages", emptySet()) ?: emptySet()).toMutableSet()
                    val filtered = allowedMap.filterNot { it.startsWith("$cleanPkg|") }.toSet()
                    prefs.edit().putStringSet("allowed_temp_packages", filtered).commit()
                } catch (e: Exception) {}

                // Reset shields & debounces so kick is immediate and cannot be bypassed
                if (lastBypassPackage == cleanPkg) {
                    lastBypassPackage = null
                    lastBypassTime = 0L
                }
                if (lastTriggeredPackage == cleanPkg) {
                    lastTriggeredPackage = null
                    lastTriggeredTime = 0L
                }

                if (blockedPackages.contains(cleanPkg)) {
                    Log.d("AppBlockService", "EXPIRED: Kicking $cleanPkg (foreground=$currentForegroundPackage)")
                    MainActivity.notifyAppBlocked(cleanPkg)
                    s.bringLauncherToFront("blockedPackageName", cleanPkg, "triggerBlockScreen")
                }
            }
        }

        /**
         * Scans all temporary unlocks and kicks any that have expired.
         */
        fun checkAllExpiredUnlocks() {
            val s = instance ?: return
            val now = System.currentTimeMillis()
            val expiredPackages = mutableListOf<String>()
            for ((pkg, expiry) in temporaryAllowedPackages) {
                if (now >= (expiry - 300L)) {
                    expiredPackages.add(pkg)
                }
            }
            for (pkg in expiredPackages) {
                checkAndKickExpiredApp(pkg)
            }
        }

        /**
         * Checks remaining time for temporarily allowed apps and triggers countdown vibrations:
         * 3 minutes remaining -> 3 vibrations (300ms each)
         * 2 minutes remaining -> 2 vibrations (600ms each)
         * Final countdown     -> 1 long vibration (1200ms) that finishes EXACTLY when the app is kicked out!
         * Only triggers if the app is currently in the foreground.
         */
        fun checkCountdownVibrations() {
            val s = instance ?: return
            val now = System.currentTimeMillis()
            for ((pkg, expiry) in temporaryAllowedPackages) {
                // Only alert if the user is currently using this unlocked app
                val isForeground = currentForegroundPackage?.equals(pkg, ignoreCase = true) == true
                if (!isForeground) continue

                val remaining = expiry - now
                if (remaining in 120_001..180_000) {
                    if (!notified3Min.contains(pkg)) {
                        notified3Min.add(pkg)
                        vibrateAlert(s, 3)
                        Log.d("AppBlockService", "COUNTDOWN VIBRATION: 3m remaining for $pkg (3x)")
                    }
                } else if (remaining in 60_001..120_000) {
                    if (!notified2Min.contains(pkg)) {
                        notified2Min.add(pkg)
                        vibrateAlert(s, 2)
                        Log.d("AppBlockService", "COUNTDOWN VIBRATION: 2m remaining for $pkg (2x)")
                    }
                } else if (remaining in 1..FINAL_VIBRATION_MS) {
                    if (!notified1Min.contains(pkg)) {
                        notified1Min.add(pkg)
                        val exactDuration = remaining.coerceIn(200L, FINAL_VIBRATION_MS)
                        vibrateSinglePulse(s, exactDuration)
                        Log.d("AppBlockService", "COUNTDOWN VIBRATION: Final $exactDuration ms for $pkg (finishes at kick)")
                    }
                }
            }
        }

        fun triggerFinalKickVibration(packageName: String) {
            val s = instance ?: return
            val cleanPkg = packageName.trim().lowercase()
            val expiry = temporaryAllowedPackages[cleanPkg] ?: return
            val now = System.currentTimeMillis()
            val remaining = expiry - now

            if (remaining > 0 && !notified1Min.contains(cleanPkg)) {
                val isForeground = currentForegroundPackage?.equals(cleanPkg, ignoreCase = true) == true
                if (isForeground) {
                    notified1Min.add(cleanPkg)
                    val exactDuration = remaining.coerceIn(200L, FINAL_VIBRATION_MS)
                    vibrateSinglePulse(s, exactDuration)
                    Log.d("AppBlockService", "FINAL KICK VIBRATION: $cleanPkg for ${exactDuration}ms (finishes exactly at kick)")
                }
            }
        }

        fun vibrateSinglePulse(context: Context, durationMs: Long) {
            try {
                val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                    vibratorManager?.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                } ?: return

                if (!vibrator.hasVibrator()) return

                val timings = longArrayOf(0L, durationMs)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val effect = if (vibrator.hasAmplitudeControl()) {
                        val amplitudes = intArrayOf(0, 255)
                        VibrationEffect.createWaveform(timings, amplitudes, -1)
                    } else {
                        VibrationEffect.createWaveform(timings, -1)
                    }
                    vibrator.vibrate(effect)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(durationMs)
                }
            } catch (e: Exception) {
                Log.e("AppBlockService", "vibrateSinglePulse failed: ${e.message}")
            }
        }

        fun vibrateAlert(context: Context, count: Int) {
            try {
                if (count == 1) {
                    vibrateSinglePulse(context, FINAL_VIBRATION_MS)
                    return
                }

                val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                    vibratorManager?.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                } ?: return

                if (!vibrator.hasVibrator()) return

                // Semakin sedikit jumlahnya, semakin panjang durasi getarnya:
                // 3x getar (sisa 3m) -> 300ms getar, 150ms jeda (3 ketukan tegas)
                // 2x getar (sisa 2m) -> 600ms getar, 200ms jeda (2 getaran mantap & lebih panjang)
                val pulseMs = when (count) {
                    3 -> 300L
                    2 -> 600L
                    else -> 400L
                }
                val sleepMs = when (count) {
                    3 -> 150L
                    2 -> 200L
                    else -> 200L
                }

                val timings = LongArray(count * 2)
                timings[0] = 0L
                for (i in 0 until count) {
                    timings[i * 2 + 1] = pulseMs
                    if (i < count - 1) {
                        timings[(i + 1) * 2] = sleepMs
                    }
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val effect = if (vibrator.hasAmplitudeControl()) {
                        // Kekuatan getar maksimal (255)
                        val amplitudes = IntArray(timings.size) { index ->
                            if (index % 2 == 1) 255 else 0
                        }
                        VibrationEffect.createWaveform(timings, amplitudes, -1)
                    } else {
                        VibrationEffect.createWaveform(timings, -1)
                    }
                    vibrator.vibrate(effect)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(timings, -1)
                }
            } catch (e: Exception) {
                Log.e("AppBlockService", "vibrateAlert failed: ${e.message}")
            }
        }

        fun updateBlockedPackages(context: Context, packages: List<String>) {
            Log.d("AppBlockService", "Flutter updateBlockedPackages: ${packages.size} apps")
            blockedPackages.clear()
            for (p in packages) {
                val clean = p.trim().lowercase()
                if (clean.isNotEmpty()) {
                    blockedPackages.add(clean)
                }
            }
            
            // Persist to SharedPreferences
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            prefs.edit().putStringSet("blocked_packages", blockedPackages.toSet()).commit()
        }

        fun allowTemporarily(context: Context, packageName: String, durationMillis: Long) {
            val pkg = packageName.trim().lowercase()
            val now = System.currentTimeMillis()
            val expiry = now + durationMillis
            
            temporaryAllowedPackages[pkg] = expiry
            
            // Activate Shield & Debounce
            lastBypassPackage = pkg
            lastBypassTime = now
            lastTriggeredPackage = pkg
            lastTriggeredTime = now
            
            // Reset countdown notification state
            notified3Min.remove(pkg)
            notified2Min.remove(pkg)
            notified1Min.remove(pkg)
            if (durationMillis <= 180_000L) notified3Min.add(pkg)
            if (durationMillis <= 120_000L) notified2Min.add(pkg)
            if (durationMillis <= FINAL_VIBRATION_MS) notified1Min.add(pkg)
            
            // Persist to SharedPreferences to prevent loss on service restart
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            val allowedMap = (prefs.getStringSet("allowed_temp_packages", emptySet()) ?: emptySet()).toMutableSet()
            allowedMap.add("$pkg|$expiry")
            prefs.edit().putStringSet("allowed_temp_packages", allowedMap).commit()
            
            // Schedule final vibration right before kick so it finishes exactly when app is kicked
            val delayForFinalVibe = durationMillis - FINAL_VIBRATION_MS
            if (delayForFinalVibe > 0) {
                handler.postDelayed({
                    triggerFinalKickVibration(pkg)
                }, delayForFinalVibe)
            }

            // Schedule instant kick when duration expires & activate continuous watchdog
            startWatchdog()
            handler.postDelayed({
                checkAndKickExpiredApp(pkg)
            }, durationMillis)
            
            Log.d("AppBlockService", "ALLOW_TEMP: $pkg until $expiry (Shield ON, Scheduler Active)")
        }

        fun updateGhadhulBasharPackages(context: Context, packages: List<String>) {
            Log.d("AppBlockService", "Flutter updateGhadhulBasharPackages: ${packages.size} apps")
            ghadhulBasharPackages.clear()
            for (p in packages) {
                ghadhulBasharPackages.add(p.trim().lowercase())
            }
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            prefs.edit().putStringSet("ghadhul_bashar_packages", ghadhulBasharPackages.toSet()).commit()
        }

        fun updateProhibitedPackages(context: Context, packages: List<String>) {
            Log.d("AppBlockService", "Flutter updateProhibitedPackages: ${packages.size} apps")
            prohibitedPackages.clear()
            for (p in packages) {
                prohibitedPackages.add(p.trim().lowercase())
            }
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            prefs.edit().putStringSet("prohibited_packages", prohibitedPackages.toSet()).commit()
        }

        fun updateStrictModeConfig(context: Context, enabled: Boolean, days: Int, untilMs: Long) {
            isStrictModeEnabled = enabled
            strictModeDays = days
            strictModeUntil = untilMs
            val now = System.currentTimeMillis()
            lastKnownTimestamp = now
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean("strict_mode_enabled", enabled)
                .putInt("strict_mode_days", days)
                .putLong("strict_mode_until", untilMs)
                .putLong("last_known_timestamp", now)
                .commit()
            Log.d("AppBlockService", "STRICT MODE CONFIG: enabled=$enabled, days=$days, until=$untilMs")
        }

        fun getStrictModeStatus(context: Context): Map<String, Any> {
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean("strict_mode_enabled", false)
            val untilMs = prefs.getLong("strict_mode_until", 0L)
            val days = prefs.getInt("strict_mode_days", 30)
            val now = System.currentTimeMillis()
            val isActive = enabled && (now < untilMs)
            val remainingMs = if (isActive) (untilMs - now).coerceAtLeast(0L) else 0L
            return mapOf(
                "enabled" to enabled,
                "isActive" to isActive,
                "days" to days,
                "untilMs" to untilMs,
                "remainingMs" to remainingMs
            )
        }

        fun isStrictActive(): Boolean {
            if (!isStrictModeEnabled) return false
            val now = System.currentTimeMillis()
            if (lastKnownTimestamp > 0 && now < (lastKnownTimestamp - 300000L)) {
                // Time set backwards detected -> keep strict mode securely locked
                return true
            }
            if (now > lastKnownTimestamp) {
                val shouldPersist = (now - lastKnownTimestamp) > 1800000L // every 30 minutes
                lastKnownTimestamp = now
                if (shouldPersist) {
                    instance?.let { ctx ->
                        ctx.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
                            .edit().putLong("last_known_timestamp", now).apply()
                    }
                }
            }
            return now < strictModeUntil
        }

        fun isSettingsOrInstallerApp(pkg: String): Boolean {
            val clean = pkg.trim().lowercase()
            return clean == "com.android.settings" ||
                   clean == "com.google.android.settings" ||
                   clean.contains("settings") ||
                   clean.contains("accessibility") ||
                   clean.contains("admin") ||
                   clean.contains("deviceadmin") ||
                   clean.contains("specialaccess") ||
                   clean.contains("packageinstaller") ||
                   clean.contains("permissioncontroller") ||
                   clean.contains("permcenter") ||
                   clean.contains("securitycenter") ||
                   clean.contains("cleanmaster") ||
                   clean.contains("safecenter") ||
                   clean.contains("securitypermission") ||
                   clean.contains("permissionmanager") ||
                   clean.contains("transsion") ||
                   clean.contains("phonemanager") ||
                   clean.contains("mobilemanager") ||
                   clean.contains("security") ||
                   clean.contains("appmanager") ||
                   clean == "com.oppo.safe" ||
                   clean == "com.iqoo.secure" ||
                   clean == "com.huawei.systemmanager" ||
                   clean == "com.hihonor.systemmanager" ||
                   clean == "com.samsung.android.sm" ||
                   clean == "com.samsung.android.sm_cn" ||
                   clean == "com.samsung.android.lool" ||
                   clean == "com.asus.mobilemanager" ||
                   clean == "com.meizu.safe"
        }

        fun detectStrictShieldViolation(
            packageName: String,
            className: String,
            rootNode: android.view.accessibility.AccessibilityNodeInfo?,
            event: AccessibilityEvent
        ): String? {
            val cleanClass = className.lowercase()
            val eventText = event.text.joinToString(" ").lowercase()

            // 1. Date & Time Settings (anti-tamper time lock across all OEMs & languages)
            val isDateTimeByClass = cleanClass.contains("datetime") ||
                cleanClass.contains("dateandtime") ||
                cleanClass.contains("zonepicker") ||
                cleanClass.contains("timezonesettings") ||
                cleanClass.contains("timepicker") ||
                cleanClass.contains("datepicker")

            val isDateTimeByText = eventText.contains("date & time") ||
                eventText.contains("date and time") ||
                eventText.contains("tanggal & waktu") ||
                eventText.contains("tanggal dan waktu") ||
                (eventText.contains("tanggal") && (eventText.contains("waktu") || eventText.contains("jam"))) ||
                (eventText.contains("date") && (eventText.contains("time") || eventText.contains("clock"))) ||
                eventText.contains("atur waktu") ||
                eventText.contains("set time")

            if (isDateTimeByClass || isDateTimeByText) {
                return "date_time"
            }

            // Also check rootNode for Date & Time toggles if class is generic SubSettings
            if (rootNode != null && (cleanClass.contains("subsettings") || cleanClass.contains("settingsactivity"))) {
                try {
                    val autoTime1 = rootNode.findAccessibilityNodeInfosByText("Automatic date & time")
                    val autoTime2 = rootNode.findAccessibilityNodeInfosByText("Gunakan waktu jaringan")
                    val autoTime3 = rootNode.findAccessibilityNodeInfosByText("Atur waktu secara otomatis")
                    val autoTime4 = rootNode.findAccessibilityNodeInfosByText("Set time automatically")
                    if (!autoTime1.isNullOrEmpty() || !autoTime2.isNullOrEmpty() ||
                        !autoTime3.isNullOrEmpty() || !autoTime4.isNullOrEmpty()) {
                        return "date_time"
                    }
                } catch (_: Exception) {}
            }

            // 2. Check if screen specifically targets Muslim Launcher 2 in Device Admin or Accessibility
            val isOurApp = eventText.contains("muslim launcher") ||
                    eventText.contains("com.kraftech.muslim_launcher_2") ||
                    rootNode?.findAccessibilityNodeInfosByText("Muslim Launcher")?.isNotEmpty() == true ||
                    rootNode?.findAccessibilityNodeInfosByText("com.kraftech.muslim_launcher_2")?.isNotEmpty() == true

            if (!isOurApp) {
                // Other apps (WhatsApp, YouTube, etc.) are 100% UNTOUCHED!
                return null
            }

            // Device Admin deactivation attempt (ONLY if Muslim Launcher is ALREADY an active Device Admin and NOT during user activation bypass):
            val isActivationBypass = System.currentTimeMillis() < deviceAdminActivationBypassUntil
            val isAdminActive = isDeviceAdminActive(instance)
            if (!isActivationBypass && isAdminActive) {
                if (isDeviceAdminScreenTargetingUs(rootNode, eventText, className, packageName)) {
                    return "device_admin"
                }
            }

            // Accessibility disable attempt:
            if (isAccessibilityScreenTargetingUs(rootNode, eventText, className, packageName)) {
                return "accessibility"
            }

            // App details (Uninstall, Clear Data, Storage) in Settings or Installers:
            if (isAppDetailsScreenTargetingUs(rootNode, eventText, className, packageName)) {
                return "app_details"
            }

            return null
        }

        private fun isAccessibilityServiceToggleScreen(searchNode: android.view.accessibility.AccessibilityNodeInfo?): Boolean {
            if (searchNode == null) return false
            try {
                val desc1 = searchNode.findAccessibilityNodeInfosByText("Membantu Anda tetap fokus")
                val desc2 = searchNode.findAccessibilityNodeInfosByText("Muslim Launcher App Blocker")
                val desc3 = searchNode.findAccessibilityNodeInfosByText("belajar Quran")
                val desc4 = searchNode.findAccessibilityNodeInfosByText("waktu ibadah")
                val desc5 = searchNode.findAccessibilityNodeInfosByText("membatasi penggunaan aplikasi")
                if (!desc1.isNullOrEmpty() || !desc2.isNullOrEmpty() || !desc3.isNullOrEmpty() || !desc4.isNullOrEmpty() || !desc5.isNullOrEmpty()) {
                    return true
                }
            } catch (_: Exception) {}
            try {
                val use1 = searchNode.findAccessibilityNodeInfosByText("Gunakan Muslim Launcher")
                val use2 = searchNode.findAccessibilityNodeInfosByText("Use Muslim Launcher")
                val use3 = searchNode.findAccessibilityNodeInfosByText("Pintasan Muslim Launcher")
                val use4 = searchNode.findAccessibilityNodeInfosByText("Muslim Launcher shortcut")
                val use5 = searchNode.findAccessibilityNodeInfosByText("Izinkan Muslim Launcher")
                val use6 = searchNode.findAccessibilityNodeInfosByText("Allow Muslim Launcher")
                if (!use1.isNullOrEmpty() || !use2.isNullOrEmpty() || !use3.isNullOrEmpty() ||
                    !use4.isNullOrEmpty() || !use5.isNullOrEmpty() || !use6.isNullOrEmpty()) {
                    return true
                }
            } catch (_: Exception) {}
            return false
        }

        fun isAppDetailsScreenTargetingUs(
            rootNode: android.view.accessibility.AccessibilityNodeInfo?,
            eventText: String,
            className: String = "",
            packageName: String = ""
        ): Boolean {
            val cleanClass = className.lowercase()
            val cleanPkg = packageName.lowercase()

            // Resolve true root of the window tree to cover child node events across all OEMs
            val searchNode = getTopmostNode(rootNode)

            val textMatches = eventText.contains("muslim launcher") || eventText.contains("com.kraftech.muslim_launcher_2")
            var nodeMatches = false

            if (searchNode != null) {
                try {
                    val matchesPkg = searchNode.findAccessibilityNodeInfosByText("com.kraftech.muslim_launcher_2")
                    val matchesName1 = searchNode.findAccessibilityNodeInfosByText("Muslim Launcher")
                    val matchesName2 = searchNode.findAccessibilityNodeInfosByText("muslim launcher")
                    nodeMatches = !matchesPkg.isNullOrEmpty() || !matchesName1.isNullOrEmpty() || !matchesName2.isNullOrEmpty()
                } catch (_: Exception) {}
            }

            val isOurApp = textMatches || nodeMatches
            if (!isOurApp) return false

            // Do NOT falsely treat Autostart, Battery, Device Admin or Accessibility as App Details
            val isAutostartOrBattery = cleanClass.contains("autostart") ||
                    cleanClass.contains("powerkeeper") ||
                    cleanClass.contains("hiddenapps") ||
                    cleanClass.contains("startup") ||
                    cleanClass.contains("whitelist") ||
                    cleanClass.contains("bgstartup") ||
                    cleanClass.contains("battery") ||
                    cleanClass.contains("optimize") ||
                    cleanClass.contains("permcenter") ||
                    cleanClass.contains("permissionmanager") ||
                    eventText.contains("autostart") ||
                    eventText.contains("mulai otomatis") ||
                    eventText.contains("mula automatik") ||
                    eventText.contains("latar belakang") ||
                    eventText.contains("penghemat baterai") ||
                    eventText.contains("battery saver")
            if (isAutostartOrBattery) return false

            val isDeviceAdmin = isDeviceAdminScreenTargetingUs(searchNode, eventText, className, packageName) ||
                    cleanClass.contains("deviceadmin") ||
                    cleanClass.contains("device_admin") ||
                    cleanClass.contains("adminsettings") ||
                    cleanClass.contains("specialaccess") ||
                    cleanPkg.contains("admin") ||
                    eventText.contains("admin perangkat") ||
                    eventText.contains("aplikasi admin") ||
                    eventText.contains("pengurus perangkat") ||
                    eventText.contains("device admin") ||
                    eventText.contains("device administrator")
            if (isDeviceAdmin) return false

            val isAccessibility = cleanClass.contains("accessibility") ||
                    eventText.contains("aksesibilitas") ||
                    eventText.contains("accessibility") ||
                    isAccessibilityServiceToggleScreen(searchNode)
            if (isAccessibility) return false

            // On Settings / App Managers / Installers across all OEMs:
            // 1. If activity class explicitly represents App Info / Details or Uninstaller, trigger immediately!
            val isExplicitAppDetailsClass = cleanClass.contains("installedappdetails") ||
                    cleanClass.contains("appinfodashboardactivity") ||
                    cleanClass.contains("applicationsdetailsactivity") ||
                    cleanClass.contains("appdetail") ||
                    cleanClass.contains("applicationdetail") ||
                    cleanClass.contains("appinfo") ||
                    cleanClass.contains("uninstalleractivity") ||
                    cleanClass.contains("uninstallalertactivity") ||
                    cleanClass.contains("uninstallconfirmation") ||
                    cleanClass.contains("secappinfo") ||
                    cleanClass.contains("appitemdetailsactivity") ||
                    cleanClass.contains("secappinfodashboardactivity") ||
                    cleanClass.contains("appinfodetailactivity") ||
                    cleanClass.contains("singleappdetails") ||
                    cleanClass.contains("appmanageractivity") ||
                    cleanClass.contains("appdetailactivity") ||
                    cleanClass.contains("manageappdetailsactivity")

            if (isExplicitAppDetailsClass) {
                return true
            }

            // 2. Check for action buttons in both searchNode and eventText (covers Samsung, Xiaomi, Oppo, Vivo, Pixel, Transsion)
            return hasAppDetailAction(searchNode, eventText)
        }

        private fun hasAppDetailAction(
            rootNode: android.view.accessibility.AccessibilityNodeInfo?,
            eventText: String
        ): Boolean {
            // Check known Android & OEM button view IDs (works across all languages and OEM skins)
            val knownButtonIds = listOf(
                // AOSP / Google Pixel / Motorola / Sony / Nothing
                "com.android.settings:id/button1_negative",
                "com.android.settings:id/button2_positive",
                "com.android.settings:id/left_button",
                "com.android.settings:id/right_button",
                "com.android.settings:id/uninstall_button",
                "com.android.settings:id/force_stop_button",
                "com.android.settings:id/btn_uninstall",
                "com.android.settings:id/btn_force_stop",
                // Samsung One UI
                "com.android.settings:id/button_uninstall",
                "com.android.settings:id/button_force_stop",
                "com.android.settings:id/bottom_btn_uninstall",
                "com.android.settings:id/bottom_btn_force_stop",
                "com.samsung.android.sm:id/uninstall",
                "com.samsung.android.sm:id/force_stop",
                // Xiaomi MIUI / HyperOS
                "com.miui.securitycenter:id/am_uninstall",
                "com.miui.securitycenter:id/am_force_stop",
                "com.miui.securitycenter:id/am_clear_data",
                "com.miui.securitycenter:id/uninstall",
                "com.miui.securitycenter:id/force_stop",
                "com.miui.securitycenter:id/clear_data",
                // Oppo / Realme / OnePlus ColorOS / OxygenOS
                "com.coloros.safecenter:id/uninstall",
                "com.coloros.safecenter:id/force_stop",
                "com.oplus.battery:id/btn_uninstall",
                "com.oplus.safecenter:id/btn_uninstall",
                // Vivo / iQOO Funtouch OS / OriginOS
                "com.vivo.permissionmanager:id/uninstall",
                "com.vivo.permissionmanager:id/force_stop",
                "com.iqoo.secure:id/uninstall",
                "com.iqoo.secure:id/force_stop",
                // Huawei / Honor EMUI / MagicOS
                "com.huawei.systemmanager:id/uninstall",
                "com.huawei.systemmanager:id/force_stop",
                // Transsion Infinix / Tecno / Itel XOS / HiOS
                "com.transsion.phonemanager:id/uninstall",
                "com.transsion.phonemanager:id/force_stop"
            )
            for (id in knownButtonIds) {
                try {
                    val found = rootNode?.findAccessibilityNodeInfosByViewId(id)
                    if (!found.isNullOrEmpty()) return true
                } catch (_: Exception) {}
            }

            val keywords = listOf(
                // English
                "uninstall", "force stop", "clear data", "clear storage", "disable", "app info", "storage & cache",
                // Indonesian
                "copot pemasangan", "copot", "uninstal", "hapus instalan", "bongkar", "paksa berhenti", "paksa henti",
                "hapus data", "hapus penyimpanan", "kelola ruang", "nonaktifkan", "info aplikasi", "penyimpanan & cache",
                // Malay
                "nyahpasang", "henti paksa", "maklumat aplikasi",
                // Arabic
                "إلغاء التثبيت", "إيقاف إجباري", "مسح البيانات", "معلومات التطبيق",
                // Turkish
                "kaldır", "zorla durdur", "verileri temizle", "uygulama bilgisi",
                // French
                "désinstaller", "forcer l'arrêt", "effacer les données", "infos sur l'application",
                // Spanish
                "desinstalar", "forzar detención", "borrar datos", "información de la aplicación"
            )
            for (kw in keywords) {
                if (eventText.contains(kw)) return true
                if (rootNode != null) {
                    try {
                        val found = rootNode.findAccessibilityNodeInfosByText(kw)
                        if (!found.isNullOrEmpty()) return true
                    } catch (_: Exception) {}
                }
            }
            return false
        }

        private fun getTopmostNode(node: android.view.accessibility.AccessibilityNodeInfo?): android.view.accessibility.AccessibilityNodeInfo? {
            var curr = node ?: return null
            try {
                while (curr.parent != null) {
                    curr = curr.parent
                }
            } catch (_: Exception) {}
            return curr
        }

        fun isAccessibilityScreenTargetingUs(
            rootNode: android.view.accessibility.AccessibilityNodeInfo?,
            eventText: String,
            className: String,
            packageName: String
        ): Boolean {
            val cleanClass = className.lowercase()
            val cleanPkg = packageName.lowercase()

            // Resolve true root of the window (traversing upwards if rootNode is a child node)
            val searchNode = getTopmostNode(rootNode)

            // CRITICAL: If screen is specifically App Details / Info, it is 100% App Info, NOT Accessibility!
            if (isAppDetailsScreenTargetingUs(searchNode, eventText, className, packageName)) {
                return false
            }

            // 1. DEFINITIVE PROOF: Accessibility Service Description from strings.xml
            // Android Settings renders this description ONLY on the accessibility service toggle screen!
            if (searchNode != null) {
                try {
                    val desc1 = searchNode.findAccessibilityNodeInfosByText("Membantu Anda tetap fokus")
                    val desc2 = searchNode.findAccessibilityNodeInfosByText("Muslim Launcher App Blocker")
                    val desc3 = searchNode.findAccessibilityNodeInfosByText("belajar Quran")
                    val desc4 = searchNode.findAccessibilityNodeInfosByText("waktu ibadah")
                    val desc5 = searchNode.findAccessibilityNodeInfosByText("membatasi penggunaan aplikasi")
                    if (!desc1.isNullOrEmpty() || !desc2.isNullOrEmpty() || !desc3.isNullOrEmpty() || !desc4.isNullOrEmpty() || !desc5.isNullOrEmpty()) {
                        Log.d("AppBlockService", "Accessibility target confirmed via unique service description")
                        return true
                    }
                } catch (_: Exception) {}
            }

            // 2. DEFINITIVE SERVICE TOGGLE LABELS (matches AOSP, Samsung, Xiaomi HyperOS/MIUI, Oppo, Vivo, Transsion)
            if (searchNode != null) {
                try {
                    val use1 = searchNode.findAccessibilityNodeInfosByText("Gunakan Muslim Launcher")
                    val use2 = searchNode.findAccessibilityNodeInfosByText("Use Muslim Launcher")
                    val use3 = searchNode.findAccessibilityNodeInfosByText("Pintasan Muslim Launcher")
                    val use4 = searchNode.findAccessibilityNodeInfosByText("Muslim Launcher shortcut")
                    val use5 = searchNode.findAccessibilityNodeInfosByText("Izinkan Muslim Launcher")
                    val use6 = searchNode.findAccessibilityNodeInfosByText("Allow Muslim Launcher")
                    if (!use1.isNullOrEmpty() || !use2.isNullOrEmpty() || !use3.isNullOrEmpty() ||
                        !use4.isNullOrEmpty() || !use5.isNullOrEmpty() || !use6.isNullOrEmpty()) {
                        Log.d("AppBlockService", "Accessibility target confirmed via specific service toggle title")
                        return true
                    }
                } catch (_: Exception) {}
            }

            // 3. Check if our app is mentioned in eventText or searchNode
            val textMatches = eventText.contains("muslim launcher") ||
                    eventText.contains("com.kraftech.muslim_launcher_2")
            var nodeMatches = false
            if (searchNode != null) {
                try {
                    val matchesPkg = searchNode.findAccessibilityNodeInfosByText("com.kraftech.muslim_launcher_2")
                    val matchesName1 = searchNode.findAccessibilityNodeInfosByText("Muslim Launcher")
                    val matchesName2 = searchNode.findAccessibilityNodeInfosByText("muslim launcher")
                    nodeMatches = !matchesPkg.isNullOrEmpty() || !matchesName1.isNullOrEmpty() || !matchesName2.isNullOrEmpty()
                } catch (_: Exception) {}
            }

            val mentionsOurApp = textMatches || nodeMatches
            if (!mentionsOurApp) return false

            // 4. Confirmation dialog / action keywords on screen (e.g. when turning off or configuring)
            val a11yActionKeywords = listOf(
                "gunakan layanan", "use service",
                "gunakan muslim launcher", "use muslim launcher",
                "izinkan muslim launcher", "allow muslim launcher",
                "pintasan muslim launcher", "muslim launcher shortcut",
                "nonaktifkan muslim launcher", "disable muslim launcher",
                "stop muslim launcher", "hentikan muslim launcher",
                "matikan muslim launcher", "turn off muslim launcher",
                "kontrol penuh atas perangkat", "full control of your device",
                "observasi tindakan anda", "observe your actions",
                "lihat dan kontrol layar", "view and control screen",
                "peringatan", "warning", "bahaya", "danger",
                "hentikan layanan", "stop service",
                "nonaktifkan layanan", "disable service",
                "matikan layanan", "turn off service"
            )
            for (kw in a11yActionKeywords) {
                if (eventText.contains(kw)) {
                    Log.d("AppBlockService", "Accessibility target confirmed via keyword in eventText: $kw")
                    return true
                }
                if (searchNode != null) {
                    try {
                        val found = searchNode.findAccessibilityNodeInfosByText(kw)
                        if (!found.isNullOrEmpty()) {
                            Log.d("AppBlockService", "Accessibility target confirmed via keyword in node: $kw")
                            return true
                        }
                    } catch (_: Exception) {}
                }
            }

            // 5. Explicit accessibility toggle activity / fragment class across OEMs
            if (cleanClass.contains("toggleaccessibilityservice") ||
                cleanClass.contains("accessibilityservicesettings") ||
                cleanClass.contains("accessibilityservicepreference") ||
                cleanClass.contains("togglefeaturepreference") ||
                cleanClass.contains("secaccessibilityservice") ||
                cleanClass.contains("miuiaccessibilityservicedetails") ||
                cleanClass.contains("accessibilitydetail") ||
                cleanClass.contains("accessibilityservicewarning") ||
                cleanClass.contains("secaccessibilitysettings") ||
                cleanClass.contains("oplusaccessibility") ||
                cleanClass.contains("vivoaccessibility")) {
                Log.d("AppBlockService", "Accessibility target confirmed via cleanClass: $cleanClass")
                return true
            }

            // 6. Context check: Screen MUST be an accessibility screen (never generic settings)
            val hasA11yBreadcrumb = if (searchNode != null) {
                val breadcrumbKeywords = listOf(
                    "aksesibilitas", "accessibility",
                    "layanan yang didownload", "downloaded apps", "downloaded services",
                    "layanan terinstal", "installed services", "installed apps",
                    "aplikasi terinstal", "layanan terpasang", "aplikasi yang diinstal",
                    "layanan diunduh"
                )
                breadcrumbKeywords.any { kw ->
                    try {
                        searchNode.findAccessibilityNodeInfosByText(kw).isNotEmpty()
                    } catch (_: Exception) { false }
                }
            } else false

            val isA11yContext = cleanClass.contains("accessibility") ||
                    cleanPkg.contains("accessibility") ||
                    eventText.contains("aksesibilitas") ||
                    eventText.contains("accessibility") ||
                    hasA11yBreadcrumb

            if (!isA11yContext) {
                return false
            }

            // 7. Known Switch/Toggle View IDs in accessibility context across OEMs
            val knownSwitchIds = listOf(
                "android:id/switch_widget",
                "com.android.settings:id/switch_widget",
                "com.android.settings:id/switch_bar",
                "com.android.settings:id/main_switch_bar",
                "com.android.settings:id/action_bar_switch",
                "com.android.settings:id/switch_text",
                "com.android.settings:id/switch_button",
                "android:id/checkbox",
                "com.android.settings:id/checkbox",
                "com.android.settings:id/sliding_button",
                "miuix:id/sliding_button",
                "com.samsung.android.settings:id/switch_widget",
                "com.coloros.widget:id/switch",
                "com.oplus.widget:id/switch",
                "com.vivo.widget:id/switch"
            )
            for (swId in knownSwitchIds) {
                try {
                    val swNode = searchNode?.findAccessibilityNodeInfosByViewId(swId)
                    if (!swNode.isNullOrEmpty()) {
                        Log.d("AppBlockService", "Accessibility target confirmed via switch ID in a11y context: $swId")
                        return true
                    }
                } catch (_: Exception) {}
            }

            // 8. Check if screen contains an active switch or checkable widget in accessibility context (deep scan up to 300 nodes)
            if (searchNode != null && mentionsOurApp) {
                val hasSwitch = hasSwitchNode(searchNode)
                if (hasSwitch) {
                    Log.d("AppBlockService", "Accessibility target confirmed via switch node in a11y context")
                    return true
                }
            }

            return false
        }

        private fun hasSwitchNode(node: android.view.accessibility.AccessibilityNodeInfo?): Boolean {
            if (node == null) return false
            val queue = ArrayDeque<android.view.accessibility.AccessibilityNodeInfo>()
            queue.add(node)
            var count = 0
            while (queue.isNotEmpty() && count < 300) {
                val current = queue.removeFirst()
                count++
                val cls = current.className?.toString() ?: ""
                if (cls.contains("Switch", ignoreCase = true) ||
                    cls.contains("ToggleButton", ignoreCase = true) ||
                    cls.contains("Sliding", ignoreCase = true) ||
                    cls.contains("CompoundButton", ignoreCase = true) ||
                    cls.contains("CheckBox", ignoreCase = true) ||
                    current.isCheckable) {
                    return true
                }
                for (i in 0 until current.childCount) {
                    val child = current.getChild(i)
                    if (child != null) {
                        queue.add(child)
                    }
                }
            }
            return false
        }

        fun isDeviceAdminScreenTargetingUs(
            rootNode: android.view.accessibility.AccessibilityNodeInfo?,
            eventText: String,
            className: String,
            packageName: String
        ): Boolean {
            val cleanClass = className.lowercase()
            val cleanPkg = packageName.lowercase()

            val isDeviceAdminContext = cleanClass.contains("deviceadmin") ||
                    cleanClass.contains("device_admin") ||
                    cleanClass.contains("adminsettings") ||
                    cleanClass.contains("specialaccess") ||
                    cleanPkg.contains("admin") ||
                    cleanPkg.contains("safecenter") ||
                    cleanPkg.contains("systemmanager") ||
                    cleanPkg.contains("phonemanager") ||
                    cleanPkg.contains("permcenter") ||
                    cleanPkg.contains("permissionmanager") ||
                    cleanPkg.contains("securitycenter") ||
                    cleanPkg.contains("knox") ||
                    cleanPkg.contains("securitylogagent") ||
                    eventText.contains("admin perangkat") ||
                    eventText.contains("aplikasi admin") ||
                    eventText.contains("pengurus perangkat") ||
                    eventText.contains("pengelola perangkat") ||
                    eventText.contains("device admin") ||
                    eventText.contains("device administrator") ||
                    eventText.contains("device administrators") ||
                    eventText.contains("device management") ||
                    eventText.contains("manage device") ||
                    eventText.contains("pentadbir peranti") ||
                    eventText.contains("toesteladministrateur") ||
                    eventText.contains("apparaatbeheerder") ||
                    eventText.contains("cihaz yöneticisi") ||
                    eventText.contains("cihaz yönetimi") ||
                    eventText.contains("administrador de dispositivos") ||
                    eventText.contains("administrador del dispositivo") ||
                    eventText.contains("administrador do dispositivo") ||
                    eventText.contains("administrateur de l'appareil") ||
                    eventText.contains("geräteadministrator") ||
                    eventText.contains("geräte-administrator") ||
                    eventText.contains("администратор устройства") ||
                    eventText.contains("设备管理器") ||
                    eventText.contains("设备管理") ||
                    eventText.contains("端末管理者") ||
                    eventText.contains("デバイス管理者") ||
                    eventText.contains("مشرف الجهاز") ||
                    eventText.contains("مشرف")

            if (!isDeviceAdminContext) return false

            val textMatches = eventText.contains("muslim launcher") ||
                    eventText.contains("com.kraftech.muslim_launcher_2") ||
                    eventText.contains("muslimdeviceadminreceiver") ||
                    eventText.contains("melindungi muslim launcher") ||
                    eventText.contains("komitmen istiqomah")
            var nodeMatches = false
            if (rootNode != null) {
                try {
                    val matchesPkg = rootNode.findAccessibilityNodeInfosByText("com.kraftech.muslim_launcher_2")
                    val matchesName1 = rootNode.findAccessibilityNodeInfosByText("Muslim Launcher")
                    val matchesName2 = rootNode.findAccessibilityNodeInfosByText("muslim launcher")
                    val matchesReceiver = rootNode.findAccessibilityNodeInfosByText("MuslimDeviceAdminReceiver")
                    val matchesDesc = rootNode.findAccessibilityNodeInfosByText("Melindungi Muslim Launcher")
                    nodeMatches = !matchesPkg.isNullOrEmpty() || !matchesName1.isNullOrEmpty() || !matchesName2.isNullOrEmpty() || !matchesReceiver.isNullOrEmpty() || !matchesDesc.isNullOrEmpty()
                } catch (_: Exception) {}
            }

            val mentionsOurApp = textMatches || nodeMatches || cleanClass.contains("deviceadminadd") || eventText.contains("melindungi muslim launcher")
            if (!mentionsOurApp) return false

            // Screen is in a Device Admin context and mentions Muslim Launcher
            return true
        }

        private var facebookBrowserSessionActive = ConcurrentHashMap<String, Boolean>()

        fun allowGhadhulBasharSession(packageName: String) {
            val pkg = packageName.trim().lowercase()
            activeGhadhulSessions.add(pkg)
            val now = System.currentTimeMillis()
            lastActiveGhadhulTimes[pkg] = now
            lastBypassPackage = pkg
            lastBypassTime = now
            lastTriggeredPackage = pkg
            lastTriggeredTime = now
            Log.d("AppBlockService", "GHADHUL SESSION ALLOWED: $pkg (Shield & Debounce Active)")
        }

        fun resetGhadhulBasharSession(packageName: String) {
            val pkg = packageName.trim().lowercase()
            activeGhadhulSessions.remove(pkg)
            lastActiveGhadhulTimes.remove(pkg)
            facebookBrowserSessionActive.remove(pkg)
            Log.d("AppBlockService", "GHADHUL SESSION RESET: $pkg")
        }

        fun clearAllGhadhulSessions() {
            activeGhadhulSessions.clear()
            lastActiveGhadhulTimes.clear()
            facebookBrowserSessionActive.clear()
            Log.d("AppBlockService", "ALL GHADHUL SESSIONS CLEARED")
        }

        fun isKeyboardOrTransientOverlay(pkg: String?): Boolean {
            if (pkg == null) return true
            val clean = pkg.trim().lowercase()
            return clean.contains("inputmethod") ||
                   clean.contains(".ime") ||
                   clean.contains("keyboard") ||
                   clean.contains("honeyboard") ||
                   clean.contains("swiftkey") ||
                   clean.contains("fleksy") ||
                   clean == "com.google.android.gms" ||
                   clean == "com.android.intentresolver"
        }

        fun isKnownBrowser(pkg: String): Boolean {
            val clean = pkg.trim().lowercase()
            return clean.contains("browser") ||
                   clean.contains("chrome") ||
                   clean.contains("firefox") ||
                   clean.contains("opera") ||
                   clean.contains("duckduckgo") ||
                   clean.contains("vivaldi") ||
                   clean == "com.microsoft.emmx" ||
                   clean == "org.torproject.torbrowser" ||
                   clean == "com.cloudmosa.puffinfree"
        }

        fun isFacebookInAppBrowser(packageName: String, className: String): Boolean {
            val isFb = packageName == "com.facebook.katana" ||
                       packageName == "com.facebook.lite" ||
                       packageName == "com.facebook.orca"
            if (!isFb) return false

            val lowerClass = className.lowercase()
            return lowerClass.contains("browserlite") ||
                   lowerClass.contains("browser.lite") ||
                   lowerClass.contains("inappbrowser") ||
                   lowerClass.contains("browseractivity") ||
                   lowerClass.contains("browserproxy")
        }

        enum class BrowserViolation {
            NONE,
            GAMBLING,
            ADULT
        }

        private val VID_WHITELIST = listOf(
            "vidio.com",
            "vidio",
            "video.google.com",
            "video.kompas.com",
            "video.tribunnews.com",
            "video.detik.com",
            "video.tempo.co",
            "video.liputan6.com",
            "youtube.com",
            "youtu.be",
            "vimeo.com",
            "dailymotion.com",
            "twitch.tv",
            "tiktok.com",
            "wikipedia",
            "wikimedia",
            "david",
            "individual",
            "provider",
            "provide",
            "evidence",
            "covid",
            "divisi",
            "division",
            "video",
            "vide",
            "nvidia",
            "vivid"
        )

        private val ADULT_KEYWORDS = listOf(
            "porn", "porno", "xxx", "bokep", "hentai", "doujin", "nekopoi", "jav", "javhd", "javsub", "dmm",
            "xnxx", "xvideos", "xhamster", "redtube", "youporn", "spankbang", "brazzers", "beeg", "eporner", "tube8",
            "onlyfans", "fansly", "fancentro", "stripchat", "chaturbate", "bongacams", "cam4", "livejasmin",
            "sange", "lendir", "colmek", "crot", "pemersatubangsa", ".xxx", ".porn", ".adult"
        )

        private val GAMBLING_KEYWORDS = listOf(
            "slot", "slot88", "slot777", "slotgacor", "gacor", "maxwin", "scatter",
            "zeus", "kakekzeus", "olympus", "mahjong", "mahjongways", "sweetbonanza",
            "pragmatic", "pragmaticplay", "pgsoft", "habanero", "spadegaming", "joker123",
            "judol", "judi", "taruhan", "betting", "agenjudi", "bandar",
            "linkgacor", "situsslot", "rtpslot", "bocoranslot", "pola-slot",
            "togel", "totomacau", "totogel", "togelonline", "singaporepools", "hongkongpools",
            "casino", "baccarat", "roulette", "blackjack", "sicbo",
            "poker88", "idnpoker", "domino99", "dominoqq", "qiuqiu", "ceme", "capsa",
            "sbobet", "bet365", "1xbet", "parimatch", "m88", "w88", "fun88", "dafabet",
            "sabungayam", "sv388", "s128", "cockfight"
        )

        fun detectFacebookBrowserViolation(
            event: AccessibilityEvent,
            rootNode: android.view.accessibility.AccessibilityNodeInfo?
        ): Pair<BrowserViolation, String> {
            val gatheredTexts = mutableListOf<String>()

            // 1. Gather text from the accessibility event
            for (charSeq in event.text) {
                val str = charSeq?.toString()?.trim()?.lowercase() ?: continue
                if (str.isNotEmpty()) gatheredTexts.add(str)
            }
            event.contentDescription?.toString()?.trim()?.lowercase()?.let {
                if (it.isNotEmpty()) gatheredTexts.add(it)
            }

            // 2. Perform a shallow search on the toolbar (max depth 3, max 25 nodes)
            // to extract header / domain / subtitle text without traversing the heavy WebView HTML DOM
            fun scanShallow(node: android.view.accessibility.AccessibilityNodeInfo?, depth: Int, count: IntArray) {
                if (node == null || depth > 3 || count[0] >= 25) return
                count[0]++

                node.text?.toString()?.trim()?.lowercase()?.let {
                    if (it.isNotEmpty() && !gatheredTexts.contains(it)) gatheredTexts.add(it)
                }
                node.contentDescription?.toString()?.trim()?.lowercase()?.let {
                    if (it.isNotEmpty() && !gatheredTexts.contains(it)) gatheredTexts.add(it)
                }

                val className = node.className?.toString()?.lowercase() ?: ""
                if (className.contains("webview")) return

                for (i in 0 until node.childCount) {
                    try {
                        val child = node.getChild(i) ?: continue
                        scanShallow(child, depth + 1, count)
                    } catch (_: Exception) {}
                }
            }

            val startNode = event.source ?: rootNode
            if (startNode != null) {
                val count = intArrayOf(0)
                scanShallow(startNode, 0, count)
            }

            if (gatheredTexts.isEmpty()) {
                return Pair(BrowserViolation.NONE, "")
            }

            val combined = gatheredTexts.joinToString(" ")

            fun isWhitelisted(text: String): Boolean {
                for (white in VID_WHITELIST) {
                    if (text.contains(white)) return true
                }
                return false
            }

            // 1. Check Gambling (Maysir - Haram Mutlak, Highest Priority)
            for (kw in GAMBLING_KEYWORDS) {
                if (combined.contains(kw)) {
                    val matchedSnippet = gatheredTexts.find { it.contains(kw) } ?: kw
                    return Pair(BrowserViolation.GAMBLING, matchedSnippet)
                }
            }

            // 2. Check Core Adult Keywords
            for (kw in ADULT_KEYWORDS) {
                if (combined.contains(kw)) {
                    val matchedSnippet = gatheredTexts.find { it.contains(kw) } ?: kw
                    return Pair(BrowserViolation.ADULT, matchedSnippet)
                }
            }

            // 3. Flexible "vid" matching with Whitelist across all gathered texts
            for (text in gatheredTexts) {
                if (text.contains("vid") && !isWhitelisted(text)) {
                    return Pair(BrowserViolation.ADULT, text)
                }
            }

            return Pair(BrowserViolation.NONE, "")
        }
    }

    private fun loadTemporaryAllowed() {
        val prefs = getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
        val saved = prefs.getStringSet("allowed_temp_packages", null)
        if (saved != null) {
            val now = System.currentTimeMillis()
            val stillvalid = mutableSetOf<String>()
            
            for (entry in saved) {
                val parts = entry.split("|")
                if (parts.size == 2) {
                    val pkg = parts[0].trim().lowercase()
                    val expiry = parts[1].toLongOrNull() ?: 0L
                    if (now < expiry) {
                        temporaryAllowedPackages[pkg] = expiry
                        stillvalid.add("$pkg|$expiry")
                        
                        val remaining = expiry - now
                        if (remaining <= 180_000L) notified3Min.add(pkg)
                        if (remaining <= 120_000L) notified2Min.add(pkg)
                        if (remaining <= FINAL_VIBRATION_MS) notified1Min.add(pkg)

                        val delayForFinalVibe = remaining - FINAL_VIBRATION_MS
                        if (delayForFinalVibe > 0) {
                            handler.postDelayed({
                                triggerFinalKickVibration(pkg)
                            }, delayForFinalVibe)
                        }

                        handler.postDelayed({
                            checkAndKickExpiredApp(pkg)
                        }, remaining)
                    }
                }
            }
            
            // Cleanup expired ones from Prefs
            if (stillvalid.size != saved.size) {
                prefs.edit().putStringSet("allowed_temp_packages", stillvalid).commit()
            }
            if (temporaryAllowedPackages.isNotEmpty()) {
                startWatchdog()
            }
        }
    }

    private fun loadBlockedPackages() {
        val prefs = getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
        val saved = prefs.getStringSet("blocked_packages", null)
        if (saved != null) {
            blockedPackages.clear()
            for (pkg in saved) {
                blockedPackages.add(pkg.trim().lowercase())
            }
        }
        val savedGhadhul = prefs.getStringSet("ghadhul_bashar_packages", null)
        if (savedGhadhul != null) {
            ghadhulBasharPackages.clear()
            for (pkg in savedGhadhul) {
                ghadhulBasharPackages.add(pkg.trim().lowercase())
            }
        }
        val savedProhibited = prefs.getStringSet("prohibited_packages", null)
        if (savedProhibited != null) {
            prohibitedPackages.clear()
            for (pkg in savedProhibited) {
                prohibitedPackages.add(pkg.trim().lowercase())
            }
        }
        isStrictModeEnabled = prefs.getBoolean("strict_mode_enabled", false)
        strictModeDays = prefs.getInt("strict_mode_days", 30)
        strictModeUntil = prefs.getLong("strict_mode_until", 0L)
        lastKnownTimestamp = prefs.getLong("last_known_timestamp", 0L)
        hasCompletedOnboarding = isOnboardingCompleted(this)
        loadTemporaryAllowed()
    }

    private val allowReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            when (action) {
                "com.muslimlauncher.ALLOW_PACKAGE" -> {
                    val pkg = intent.getStringExtra("packageName")?.trim()?.lowercase()
                    val duration = intent.getLongExtra("durationMillis", 3600000L)
                    if (pkg != null) {
                        val now = System.currentTimeMillis()
                        val expiry = now + duration
                        temporaryAllowedPackages[pkg] = expiry
                        lastBypassPackage = pkg
                        lastBypassTime = now
                        notified3Min.remove(pkg)
                        notified2Min.remove(pkg)
                        notified1Min.remove(pkg)
                        if (duration <= 180_000L) notified3Min.add(pkg)
                        if (duration <= 120_000L) notified2Min.add(pkg)
                        if (duration <= FINAL_VIBRATION_MS) notified1Min.add(pkg)

                        val delayForFinalVibe = duration - FINAL_VIBRATION_MS
                        if (delayForFinalVibe > 0) {
                            handler.postDelayed({
                                triggerFinalKickVibration(pkg)
                            }, delayForFinalVibe)
                        }

                        startWatchdog()
                        Log.d("AppBlockService", "BROADCAST RECEIVED: Allowed $pkg (Shield ON)")
                    }
                }
                "com.muslimlauncher.ALLOW_GHADHUL_BASHAR" -> {
                    val pkg = intent.getStringExtra("packageName")?.trim()?.lowercase()
                    if (pkg != null) {
                        allowGhadhulBasharSession(pkg)
                    }
                }
                "com.muslimlauncher.RESET_GHADHUL_BASHAR" -> {
                    val pkg = intent.getStringExtra("packageName")?.trim()?.lowercase()
                    if (pkg != null) {
                        resetGhadhulBasharSession(pkg)
                    }
                }
                "com.muslimlauncher.BYPASS_SUPPORT_DEV" -> {
                    prepareSupportDeveloperBypass()
                }
                "com.muslimlauncher.BYPASS_DEVICE_ADMIN_ACTIVATION" -> {
                    allowDeviceAdminActivationTemporarily()
                }
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        try {
            val type = event.eventType
            val isWindowState = type == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            val isWindowContent = type == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED

            if (!isWindowState && !isWindowContent) return

            val packageName = event.packageName?.toString()?.trim()?.lowercase() ?: return
            val className = event.className?.toString()?.lowercase() ?: ""

            // Optimization: If it's a content change (scrolling/typing/layout updates),
            // ONLY process if it's Settings so there's zero overhead for all normal apps!
            if (isWindowContent) {
                val isTargetApp = isSettingsOrInstallerApp(packageName)
                if (!isTargetApp) return
            }

            // Skip transient overlays, keyboards (IMEs), and system dialogs so they don't corrupt foreground state
            if (isKeyboardOrTransientOverlay(packageName)) {
                return
            }

            // Skip our own app
            if (packageName == this.packageName) {
                if (hasEnteredBypassedScreen) {
                    resetStandardSettingsBypass(force = true)
                }
                return
            }

            val previousPackage = currentForegroundPackage
            currentForegroundPackage = packageName

            val now = System.currentTimeMillis()
            if (packageName == lastTriggeredPackage && (now - lastTriggeredTime) < 800L) {
                return
            }

            // Scan for any expired temporary unlocks and countdown alerts on every accessibility event
            // This is a backup for postDelayed timers that may be deferred by Doze mode
            if (temporaryAllowedPackages.isNotEmpty()) {
                checkCountdownVibrations()
                checkAllExpiredUnlocks()
            }

            // 0.0 PRIORITAS 0.0: ANTI-TAMPER SHIELD (STRICT MODE PROTECTION)
            val activeNode = rootInActiveWindow ?: getTopmostNode(event.source) ?: event.source

            // 0.00 BYPASS: If user explicitly requested Device Admin activation in our app, allow full interaction on Settings / Admin screens
            val isDeviceAdminActivationBypass = now < deviceAdminActivationBypassUntil
            if (isDeviceAdminActivationBypass) {
                val cleanPkg = packageName.lowercase()
                val cleanCls = className.lowercase()
                val isSettingsOrAdminOrSecurity = isSettingsOrInstallerApp(packageName) ||
                        cleanPkg.contains("settings") ||
                        cleanPkg.contains("admin") ||
                        cleanPkg.contains("security") ||
                        cleanPkg.contains("permission") ||
                        cleanPkg.contains("safecenter") ||
                        cleanPkg.contains("systemmanager") ||
                        cleanPkg.contains("phonemanager") ||
                        cleanPkg.contains("permcenter") ||
                        cleanPkg.contains("securitycenter") ||
                        cleanCls.contains("admin") ||
                        cleanCls.contains("deviceadmin") ||
                        cleanCls.contains("specialaccess")

                if (isSettingsOrAdminOrSecurity) {
                    val isExplicitUninstall = cleanCls.contains("uninstalleractivity") ||
                            cleanCls.contains("uninstallalertactivity") ||
                            cleanCls.contains("uninstallconfirmation")
                    if (!isExplicitUninstall) {
                        Log.d("AppBlockService", "Allowing Device Admin activation screen during active activation bypass window: pkg=$packageName cls=$className")
                        return
                    }
                }
            }

            if (isStrictActive()) {
                val isSettingsOrInstaller = isSettingsOrInstallerApp(packageName)
                val isA11yContext = packageName.contains("accessibility") || className.lowercase().contains("accessibility")
                val cleanPkg = packageName.lowercase()
                val isDeviceAdminContext = cleanPkg.contains("admin") ||
                        cleanPkg.contains("safecenter") ||
                        cleanPkg.contains("securitycenter") ||
                        cleanPkg.contains("systemmanager") ||
                        cleanPkg.contains("phonemanager") ||
                        cleanPkg.contains("permcenter") ||
                        cleanPkg.contains("knox") ||
                        className.lowercase().contains("deviceadmin") ||
                        className.lowercase().contains("device_admin") ||
                        className.lowercase().contains("adminsettings") ||
                        className.lowercase().contains("specialaccess") ||
                        event.text.joinToString(" ").lowercase().contains("admin")
                if (isSettingsOrInstaller || isA11yContext || isDeviceAdminContext) {
                    val shieldReason = detectStrictShieldViolation(packageName, className, activeNode, event)
                    if (shieldReason != null) {
                        Log.d("AppBlockService", "STRICT SHIELD TRIGGERED: reason=$shieldReason in pkg=$packageName cls=$className")
                        lastTriggeredPackage = packageName
                        lastTriggeredTime = now
                        MainActivity.notifyStrictShieldTriggered(shieldReason)
                        bringLauncherToFront("strictShieldReason", shieldReason, "triggerStrictShieldScreen")
                        return
                    }
                }
            } else {
                // 0.0B PRIORITAS 0.0B: STANDARD MODE REFLECTION OVERLAY
                // When user accesses Muslim Launcher 2 in Settings (App Info) or Accessibility, prompt with spiritual reflection
                val isSettingsOrInstaller = isSettingsOrInstallerApp(packageName)
                val isA11yContext = packageName.contains("accessibility") || className.lowercase().contains("accessibility")
                if (isSettingsOrInstaller || isA11yContext) {
                    val cleanClass = className.lowercase()
                    val eventText = event.text.joinToString(" ").lowercase()

                    // Exclude Autostart & Battery Optimization completely from Standard Mode overlay
                    val isAutostartOrBattery = cleanClass.contains("autostart") ||
                            cleanClass.contains("powerkeeper") ||
                            cleanClass.contains("hiddenapps") ||
                            cleanClass.contains("startup") ||
                            cleanClass.contains("whitelist") ||
                            cleanClass.contains("bgstartup") ||
                            cleanClass.contains("battery") ||
                            cleanClass.contains("optimize") ||
                            cleanClass.contains("permcenter") ||
                            cleanClass.contains("permissionmanager") ||
                            eventText.contains("autostart") ||
                            eventText.contains("mulai otomatis") ||
                            eventText.contains("mula automatik") ||
                            eventText.contains("latar belakang") ||
                            eventText.contains("penghemat baterai") ||
                            eventText.contains("battery saver")
                    if (isAutostartOrBattery) {
                        return
                    }

                    // Grace period right after service connection so enabling the service in Step 4 doesn't trigger reflection
                    if ((now - serviceConnectedTime) < 3500L) {
                        return
                    }

                    // 1. Check App Details first (Settings -> Apps -> Muslim Launcher 2)
                    val targetsAppDetails = isAppDetailsScreenTargetingUs(activeNode, eventText, className, packageName)

                    // 2. Check Accessibility screen second (Settings -> Accessibility -> Muslim Launcher 2)
                    val targetsAccessibility = !targetsAppDetails && isAccessibilityScreenTargetingUs(activeNode, eventText, className, packageName)

                    // Exclude Device Admin completely from Standard Mode overlay
                    if (!targetsAccessibility && !targetsAppDetails) {
                        val isDeviceAdmin = isDeviceAdminScreenTargetingUs(activeNode, eventText, className, packageName) ||
                                cleanClass.contains("deviceadmin") ||
                                cleanClass.contains("device_admin") ||
                                cleanClass.contains("adminsettings") ||
                                cleanClass.contains("specialaccess")
                        if (isDeviceAdmin) {
                            return
                        }
                    }

                    val isTargetingUs = targetsAppDetails || targetsAccessibility

                    if (isTargetingUs) {
                        val isBypassValid = (now <= standardModeBypassExpiry)
                        if (!isBypassValid) {
                            val source = when {
                                targetsAppDetails -> "settings"
                                targetsAccessibility -> "accessibility"
                                else -> "settings"
                            }
                            Log.d("AppBlockService", "STANDARD REFLECTION TRIGGERED: source=$source in pkg=$packageName cls=$className")
                            lastTriggeredPackage = packageName
                            lastTriggeredTime = now
                            lastStandardReflectionSource = source
                            MainActivity.notifyStandardReflectionTriggered()
                            bringLauncherToFront("standardReflection", "true", "triggerStandardReflectionScreen", source)
                            return
                        } else {
                            hasEnteredBypassedScreen = true
                        }
                    } else {
                        // User was on Muslim Launcher screen, but backed out to the list / another settings menu
                        if (hasEnteredBypassedScreen) {
                            Log.d("AppBlockService", "User exited Muslim Launcher screen in Settings -> resetting bypass")
                            resetStandardSettingsBypass(force = true)
                        }
                    }

                    // Fallback delayed check for activity resume from background (when views take 150-250ms to attach)
                    if (isWindowState && !isTargetingUs) {
                        val capturedPkg = packageName
                        val capturedCls = className
                        handler.postDelayed({
                            try {
                                val curPkg = currentForegroundPackage
                                if (curPkg?.equals(capturedPkg, ignoreCase = true) == true) {
                                    val active = rootInActiveWindow ?: getTopmostNode(null)
                                    if (active != null) {
                                        val isAppInfo = isAppDetailsScreenTargetingUs(active, "", capturedCls, capturedPkg)
                                        val isA11y = !isAppInfo && isAccessibilityScreenTargetingUs(active, "", capturedCls, capturedPkg)
                                        if (isA11y || isAppInfo) {
                                            val curNow = System.currentTimeMillis()
                                            if (curNow > standardModeBypassExpiry) {
                                                val src = if (isAppInfo) "settings" else "accessibility"
                                                Log.d("AppBlockService", "STANDARD REFLECTION TRIGGERED (delayed resume check): source=$src")
                                                lastTriggeredPackage = capturedPkg
                                                lastTriggeredTime = curNow
                                                lastStandardReflectionSource = src
                                                MainActivity.notifyStandardReflectionTriggered()
                                                bringLauncherToFront("standardReflection", "true", "triggerStandardReflectionScreen", src)
                                            }
                                        }
                                    }
                                }
                            } catch (_: Exception) {}
                        }, 250L)
                    }
                } else {
                    // Navigated away to an app other than Settings / Accessibility
                    if (hasEnteredBypassedScreen) {
                        resetStandardSettingsBypass(force = true)
                    }
                }
            }

            // 0. PRIORITAS 0: PROHIBITED BROWSER CHECK (Dilarang Total - Tanpa Poin/Waktu)
            if (prohibitedPackages.contains(packageName)) {
                Log.d("AppBlockService", "PROHIBITED BROWSER DETECTED: $packageName")
                lastTriggeredPackage = packageName
                lastTriggeredTime = now
                MainActivity.notifyAppProhibited(packageName)
                bringLauncherToFront("prohibitedPackageName", packageName, "triggerProhibitedScreen")
                return // DILARANG TOTAL SAMA SEKALI!
            }

            // Khusus: Bypass Ghadhul Bashar jika dibuka via tombol "Dukung Developer" (Trakteer / Ko-fi)
            val isSupportDevBypass = (now < bypassSupportDeveloperUntil) &&
                    (isKnownBrowser(packageName) || ghadhulBasharPackages.contains(packageName))
            if (isSupportDevBypass) {
                Log.d("AppBlockService", "GHADHUL BASHAR: Bypassed specifically for Dukung Developer ($packageName)")
                bypassSupportDeveloperUntil = 0L // Segera reset agar hanya berlaku 1 kali (one-time)
                lastBypassPackage = packageName
                lastBypassTime = now
                return
            }

            // 1. TRANSITION SHIELD (Highest Priority)
            // Immunity period for recently unlocked or allowed apps (15 seconds)
            // Memastikan transisi awal ke aplikasi yang baru dibuka kunci / diizinkan tidak memantul
            val isWithinBypassShield = (packageName == lastBypassPackage && (now - lastBypassTime) < 15000L)
            if (isWithinBypassShield) {
                if (ghadhulBasharPackages.contains(packageName)) {
                    lastActiveGhadhulTimes[packageName] = now
                }
                return 
            }

            // 2. PRIORITAS 1: NON-PRODUCTIVE BLOCK CHECK (Kunci Utama)
            if (blockedPackages.contains(packageName)) {
                val expiry = temporaryAllowedPackages[packageName]
                val isAllowed = expiry != null && now < expiry
                if (!isAllowed) {
                    Log.d("AppBlockService", "BLOCK (Non-Productive): Detect $packageName")
                    lastTriggeredPackage = packageName
                    lastTriggeredTime = now
                    MainActivity.notifyAppBlocked(packageName)
                    bringLauncherToFront("blockedPackageName", packageName, "triggerBlockScreen")
                    return // KUNCI NON-PRODUKTIF ADALAH YANG UTAMA!
                }
            }

            // 3. PRIORITAS 2: GHADHUL BASHAR CHECK (Pengingat Murni)
            // Hanya dieksekusi jika aplikasi bukan aplikasi non-produktif terkunci (atau sudah dibuka kuncinya)
            if (ghadhulBasharPackages.contains(packageName)) {
                val lastActive = lastActiveGhadhulTimes[packageName]
                val isIdleExpired = lastActive != null && (now - lastActive) > (30 * 60 * 1000)
                
                if (isIdleExpired) {
                    activeGhadhulSessions.remove(packageName)
                    facebookBrowserSessionActive.remove(packageName)
                }

                val hasActiveSession = activeGhadhulSessions.contains(packageName)
                val isBrowser = isKnownBrowser(packageName)
                val isFbBrowser = isFacebookInAppBrowser(packageName, className)

                // Track status sesi Facebook in-app browser
                if (!isFbBrowser) {
                    // Berada di feed / aktivitas biasa Facebook (bukan in-app browser)
                    facebookBrowserSessionActive[packageName] = false
                } else {
                    // One-shot scan: Check toolbar/header for Gambling or Adult content violations (with flexible 'vid' + whitelist)
                    val (violation, targetInfo) = detectFacebookBrowserViolation(event, rootInActiveWindow)
                    if (violation == BrowserViolation.GAMBLING) {
                        Log.d("AppBlockService", "FACEBOOK BROWSER VIOLATION (GAMBLING): $targetInfo")
                        facebookBrowserSessionActive[packageName] = false
                        lastTriggeredPackage = packageName
                        lastTriggeredTime = now
                        try {
                            performGlobalAction(GLOBAL_ACTION_BACK)
                        } catch (_: Exception) {}
                        val targetLabel = "Judi Online"
                        MainActivity.notifyAppProhibited(targetLabel)
                        bringLauncherToFront("prohibitedPackageName", targetLabel, "triggerProhibitedScreen")
                        return
                    } else if (violation == BrowserViolation.ADULT) {
                        Log.d("AppBlockService", "FACEBOOK BROWSER VIOLATION (ADULT): $targetInfo")
                        facebookBrowserSessionActive[packageName] = false
                        lastTriggeredPackage = packageName
                        lastTriggeredTime = now
                        try {
                            performGlobalAction(GLOBAL_ACTION_BACK)
                        } catch (_: Exception) {}
                        val targetLabel = "Konten Dewasa"
                        MainActivity.notifyAppProhibited(targetLabel)
                        bringLauncherToFront("prohibitedPackageName", targetLabel, "triggerProhibitedScreen")
                        return
                    }
                }

                if (hasActiveSession) {
                    if (isFbBrowser) {
                        // Khusus Facebook & Facebook Lite:
                        // Deteksi saat pengguna membuka link internal via in-app browser
                        val isAlreadyInFbBrowser = facebookBrowserSessionActive[packageName] == true
                        if (isAlreadyInFbBrowser || isWithinBypassShield) {
                            // Sesi browser saat ini sedang aktif dibaca oleh user -> jangan loop
                            facebookBrowserSessionActive[packageName] = true
                            lastActiveGhadhulTimes[packageName] = now
                            return
                        } else {
                            // Link baru saja diklik di dalam Facebook! Tampilkan pengingat Ghadhul Bashar
                            Log.d("AppBlockService", "GHADHUL BASHAR: Facebook In-App Browser detected for $packageName ($className)")
                            facebookBrowserSessionActive[packageName] = true
                            lastTriggeredPackage = packageName
                            lastTriggeredTime = now
                            MainActivity.notifyGhadhulBashar(packageName)
                            bringLauncherToFront("ghadhulBasharPackageName", packageName, "triggerGhadhulBasharScreen")
                            return
                        }
                    } else if (!isBrowser) {
                        // Aplikasi non-browser (seperti TikTok, Instagram, Twitter/X, atau feed Facebook):
                        // Selama sesi aktif (idle < 30 menit), izinkan semua aktivitas internal:
                        // - Menonton video / scrolling
                        // - Menonton Live streaming
                        // - Membuka keyboard / komentar / posting ulang (repost)
                        // - Menjelajah profil, tab, atau keranjang belanja internal
                        lastActiveGhadhulTimes[packageName] = now
                        return
                    } else {
                        // Aplikasi Browser (Chrome, Firefox, dll):
                        // Deteksi apakah browser dibuka karena klik link dari aplikasi eksternal (WhatsApp, Telegram, dll)
                        val isLauncherOrSystem = previousPackage == null ||
                            previousPackage == this.packageName ||
                            previousPackage == "com.android.systemui" ||
                            previousPackage == packageName ||
                            previousPackage == "android" ||
                            previousPackage.endsWith(".launcher") ||
                            previousPackage.contains("launcher") ||
                            previousPackage.contains("home") ||
                            isKeyboardOrTransientOverlay(previousPackage)

                        // Chrome Custom Tab dari aplikasi luar
                        val isCustomTabFromExternal = className.contains("customtab") && previousPackage != packageName
                        val isLinkFromExternalApp = (!isLauncherOrSystem) || isCustomTabFromExternal

                        if (!isLinkFromExternalApp || isWithinBypassShield) {
                            // Pengguna hanya berpindah aplikasi dan kembali lagi (multitasking biasa) -> izinkan tanpa menampilkan overlay
                            lastActiveGhadhulTimes[packageName] = now
                            return
                        }
                    }
                }

                // Tampilkan overlay jika:
                // 1. Peluncuran baru / idle > 30 menit (!hasActiveSession), ATAU
                // 2. Browser dibuka dari klik link aplikasi eksternal / in-app browser Facebook
                Log.d("AppBlockService", "GHADHUL BASHAR: Triggered for $packageName (isBrowser=$isBrowser, activeSession=$hasActiveSession)")
                lastTriggeredPackage = packageName
                lastTriggeredTime = now
                MainActivity.notifyGhadhulBashar(packageName)
                bringLauncherToFront("ghadhulBasharPackageName", packageName, "triggerGhadhulBasharScreen")
                return
            }
        } catch (e: Exception) {
            Log.e("AppBlockService", "Crash in onAccessibilityEvent: ${e.message}")
        }
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        serviceConnectedTime = System.currentTimeMillis()

        try {
            val info = serviceInfo ?: android.accessibilityservice.AccessibilityServiceInfo()
            info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            info.feedbackType = android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_GENERIC
            info.flags = info.flags or
                android.accessibilityservice.AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                android.accessibilityservice.AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            serviceInfo = info
        } catch (e: Exception) {
            Log.w("AppBlockService", "Failed to update serviceInfo: ${e.message}")
        }

        loadBlockedPackages()
        
        // Register receiver for instant unlock & session signals
        val filter = IntentFilter().apply {
            addAction("com.muslimlauncher.ALLOW_PACKAGE")
            addAction("com.muslimlauncher.ALLOW_GHADHUL_BASHAR")
            addAction("com.muslimlauncher.RESET_GHADHUL_BASHAR")
            addAction("com.muslimlauncher.BYPASS_SUPPORT_DEV")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(allowReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(allowReceiver, filter)
        }
        
        Log.d("AppBlockService", "Accessibility Service Connected with Receiver (Protected)")
    }

    override fun onDestroy() {
        try {
            if (instance == this) instance = null
            handler.removeCallbacksAndMessages(null)
            unregisterReceiver(allowReceiver)
        } catch (e: Exception) {}
        super.onDestroy()
    }

    /**
     * Brings the launcher to foreground using a multi-layered approach for maximum reliability:
     * 1. performGlobalAction(HOME) — Works on ALL Android versions (API 16+), bypasses
     *    Android 10+ background activity launch restrictions. Simulates the HOME button press.
     * 2. startActivity with intent extras — Delivers the overlay trigger data to Flutter.
     * 3. Retry with 500ms delay if startActivity fails on first attempt.
     *
     * This dual approach ensures the overlay works across:
     * - All Android versions (7.0 to 15+)
     * - All OEM skins (Samsung, Xiaomi, Oppo, Vivo, Huawei, etc.)
     * - All launch contexts (recent apps, notifications, widgets, shortcuts, other apps)
     * - Aggressive battery optimization modes (Doze, App Standby)
     */
    private fun bringLauncherToFront(packageNameKey: String, packageNameValue: String, triggerKey: String, sourceExtra: String? = null) {
        val cleanPkg = packageNameValue.trim().lowercase()

        // LAYER 1: performGlobalAction(HOME) — Immediately minimizes the foreground app
        // and bypasses Android 10+ background activity launch (BAL) restrictions across all devices
        try {
            performGlobalAction(GLOBAL_ACTION_HOME)
        } catch (e: Exception) {
            Log.w("AppBlockService", "performGlobalAction(HOME) failed: ${e.message}")
        }

        // LAYER 2: Explicit Intent to MainActivity with custom action to prevent HOME categorization
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.muslimlauncher.SHOW_BLOCK_OVERLAY"
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra(packageNameKey, cleanPkg)
            putExtra(triggerKey, true)
            if (sourceExtra != null) {
                putExtra("standardReflectionSource", sourceExtra)
            }
        }

        // LAYER 3: PendingIntent with MODE_BACKGROUND_ACTIVITY_START_ALLOWED (bypasses Android 14+ BAL restrictions)
        try {
            val pendingIntent = PendingIntent.getActivity(
                this,
                (System.currentTimeMillis() % 10000).toInt(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            if (Build.VERSION.SDK_INT >= 34) {
                val options = ActivityOptions.makeBasic().apply {
                    setPendingIntentBackgroundActivityStartMode(
                        ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                    )
                }
                pendingIntent.send(this, 0, null, null, null, null, options.toBundle())
            } else {
                pendingIntent.send()
            }
        } catch (e: Exception) {
            Log.w("AppBlockService", "PendingIntent.send failed: ${e.message}")
        }

        // LAYER 4: Direct startActivity fallback
        try {
            startActivity(intent)
        } catch (e: Exception) {
            Log.w("AppBlockService", "startActivity failed: ${e.message}")
        }

        // LAYER 5: Retry with 400ms delay to catch any window transition delays
        handler.postDelayed({
            try {
                startActivity(intent)
            } catch (retryEx: Exception) {
                Log.e("AppBlockService", "Retry startActivity failed: ${retryEx.message}")
            }
        }, 400L)
    }
}
