package com.kraftech.muslim_launcher_2

import android.accessibilityservice.AccessibilityService
import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.os.Build
import android.content.IntentFilter
import java.util.concurrent.ConcurrentHashMap
import java.util.Collections

class AppBlockService : AccessibilityService() {
    companion object {
        private var instance: AppBlockService? = null
        private val handler = android.os.Handler(android.os.Looper.getMainLooper())
        private var blockedPackages = Collections.synchronizedSet(mutableSetOf<String>())
        private var temporaryAllowedPackages = ConcurrentHashMap<String, Long>()
        
        // Ghadhul Bashar state tracking
        private var ghadhulBasharPackages = Collections.synchronizedSet(mutableSetOf<String>())
        private var activeGhadhulSessions = Collections.synchronizedSet(mutableSetOf<String>())
        private var lastActiveGhadhulTimes = ConcurrentHashMap<String, Long>()

        // Prohibited bypass browsers (Permanently blocked in restricted regions)
        private var prohibitedPackages = Collections.synchronizedSet(mutableSetOf<String>())

        // Transition Shield: Prevent loop during the first 10 seconds of unlock
        private var lastBypassPackage: String? = null
        private var lastBypassTime: Long = 0
        private var currentForegroundPackage: String? = null

        // Debounce to prevent multiple back-to-back startActivity calls on rapid accessibility events
        private var lastTriggeredPackage: String? = null
        private var lastTriggeredTime: Long = 0

        private val watchdogRunnable = object : Runnable {
            override fun run() {
                if (temporaryAllowedPackages.isNotEmpty()) {
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
            
            // Persist to SharedPreferences to prevent loss on service restart
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            val allowedMap = (prefs.getStringSet("allowed_temp_packages", emptySet()) ?: emptySet()).toMutableSet()
            allowedMap.add("$pkg|$expiry")
            prefs.edit().putStringSet("allowed_temp_packages", allowedMap).commit()
            
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
            Log.d("AppBlockService", "GHADHUL SESSION RESET: $pkg")
        }

        fun clearAllGhadhulSessions() {
            activeGhadhulSessions.clear()
            lastActiveGhadhulTimes.clear()
            Log.d("AppBlockService", "ALL GHADHUL SESSIONS CLEARED")
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
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        try {
            // Only process window state changes (app switches)
            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

            val packageName = event.packageName?.toString()?.trim()?.lowercase() ?: return
            val className = event.className?.toString()?.lowercase() ?: ""

            val previousPackage = currentForegroundPackage
            currentForegroundPackage = packageName
            
            // Skip our own app
            if (packageName == this.packageName) return

            val now = System.currentTimeMillis()
            if (packageName == lastTriggeredPackage && (now - lastTriggeredTime) < 800L) {
                return
            }

            // Scan for any expired temporary unlocks on every accessibility event
            // This is a backup for postDelayed timers that may be deferred by Doze mode
            if (temporaryAllowedPackages.isNotEmpty()) {
                checkAllExpiredUnlocks()
            }

            // 0. PRIORITAS 0: PROHIBITED BYPASS BROWSER CHECK (Dilarang Total - Tanpa Poin/Waktu)
            if (prohibitedPackages.contains(packageName)) {
                Log.d("AppBlockService", "PROHIBITED BROWSER DETECTED: $packageName")
                lastTriggeredPackage = packageName
                lastTriggeredTime = now
                MainActivity.notifyAppProhibited(packageName)
                bringLauncherToFront("prohibitedPackageName", packageName, "triggerProhibitedScreen")
                return // DILARANG TOTAL SAMA SEKALI!
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
                }

                val hasActiveSession = activeGhadhulSessions.contains(packageName)

                // Deteksi apakah browser dibuka karena klik link dari aplikasi eksternal (WhatsApp, Telegram, IG, dll)
                val isLauncherOrSystem = previousPackage == null ||
                    previousPackage == this.packageName ||
                    previousPackage == "com.android.systemui" ||
                    previousPackage == packageName ||
                    previousPackage == "android" ||
                    previousPackage.endsWith(".launcher") ||
                    previousPackage.contains("launcher") ||
                    previousPackage.contains("home")

                val isCustomTab = className.contains("customtab")
                val isLinkFromExternalApp = (!isLauncherOrSystem) || isCustomTab

                if (hasActiveSession && !isLinkFromExternalApp) {
                    // Pengguna hanya berpindah aplikasi dan kembali lagi (multitasking biasa) -> izinkan tanpa menampilkan overlay
                    lastActiveGhadhulTimes[packageName] = now
                    return 
                } else if (hasActiveSession && isWithinBypassShield) {
                    // Baru saja diizinkan dalam 15 detik terakhir untuk link eksternal / customtab -> izinkan tanpa loop
                    lastActiveGhadhulTimes[packageName] = now
                    return
                } else {
                    // Tampilkan overlay jika:
                    // 1. Buka link dari aplikasi eksternal (isLinkFromExternalApp == true), ATAU
                    // 2. Peluncuran baru / idle > 30 menit (!hasActiveSession)
                    Log.d("AppBlockService", "GHADHUL BASHAR: Triggered for $packageName (isExternalLink=$isLinkFromExternalApp, activeSession=$hasActiveSession)")
                    lastTriggeredPackage = packageName
                    lastTriggeredTime = now
                    MainActivity.notifyGhadhulBashar(packageName)
                    bringLauncherToFront("ghadhulBasharPackageName", packageName, "triggerGhadhulBasharScreen")
                    return
                }
            }
        } catch (e: Exception) {
            Log.e("AppBlockService", "Crash in onAccessibilityEvent: ${e.message}")
        }
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        loadBlockedPackages()
        
        // Register receiver for instant unlock & session signals
        val filter = IntentFilter().apply {
            addAction("com.muslimlauncher.ALLOW_PACKAGE")
            addAction("com.muslimlauncher.ALLOW_GHADHUL_BASHAR")
            addAction("com.muslimlauncher.RESET_GHADHUL_BASHAR")
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
    private fun bringLauncherToFront(packageNameKey: String, packageNameValue: String, triggerKey: String) {
        val cleanPkg = packageNameValue.trim().lowercase()

        // LAYER 1: performGlobalAction(HOME) — Immediately minimizes the blocked app
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
