package com.kraftech.muslim_launcher_2

import android.accessibilityservice.AccessibilityService
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

        fun checkAndKickExpiredApp(packageName: String) {
            val s = instance ?: return
            val now = System.currentTimeMillis()
            val expiry = temporaryAllowedPackages[packageName]
            if (expiry != null && now >= expiry) {
                temporaryAllowedPackages.remove(packageName)
                val activePackage = currentForegroundPackage
                if (activePackage == packageName && blockedPackages.contains(packageName)) {
                    Log.d("AppBlockService", "EXPIRED WHILE IN APP: Kicking $packageName")
                    MainActivity.notifyAppBlocked(packageName)
                    val launchIntent = s.packageManager.getLaunchIntentForPackage(s.packageName)?.apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        putExtra("blockedPackageName", packageName)
                        putExtra("triggerBlockScreen", true)
                    }
                    s.startActivity(launchIntent)
                }
            }
        }

        fun updateBlockedPackages(context: Context, packages: List<String>) {
            Log.d("AppBlockService", "Flutter updateBlockedPackages: ${packages.size} apps")
            blockedPackages.clear()
            blockedPackages.addAll(packages)
            
            // Persist to SharedPreferences
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            prefs.edit().putStringSet("blocked_packages", blockedPackages.toSet()).commit()
        }

        fun allowTemporarily(context: Context, packageName: String, durationMillis: Long) {
            val pkg = packageName.trim().lowercase()
            val now = System.currentTimeMillis()
            val expiry = now + durationMillis
            
            temporaryAllowedPackages[pkg] = expiry
            
            // Activate Shield
            lastBypassPackage = pkg
            lastBypassTime = now
            
            // Persist to SharedPreferences to prevent loss on service restart
            val prefs = context.getSharedPreferences("app_block_prefs", Context.MODE_PRIVATE)
            val allowedMap = (prefs.getStringSet("allowed_temp_packages", emptySet()) ?: emptySet()).toMutableSet()
            allowedMap.add("$pkg|$expiry")
            prefs.edit().putStringSet("allowed_temp_packages", allowedMap).commit()
            
            // Schedule instant kick when duration expires
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
            Log.d("AppBlockService", "GHADHUL SESSION ALLOWED: $pkg")
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
            if (packageName == lastTriggeredPackage && (now - lastTriggeredTime) < 1200L) {
                return
            }

            // 0. PRIORITAS 0: PROHIBITED BYPASS BROWSER CHECK (Dilarang Total - Tanpa Poin/Waktu)
            if (prohibitedPackages.contains(packageName)) {
                Log.d("AppBlockService", "PROHIBITED BROWSER DETECTED: $packageName")
                lastTriggeredPackage = packageName
                lastTriggeredTime = now
                MainActivity.notifyAppProhibited(packageName)
                
                val launchIntent = packageManager.getLaunchIntentForPackage(this.packageName)?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                    putExtra("prohibitedPackageName", packageName)
                    putExtra("triggerProhibitedScreen", true)
                }
                startActivity(launchIntent)
                return // DILARANG TOTAL SAMA SEKALI!
            }

            // 1. TRANSITION SHIELD (Highest Priority)
            // Immunity period for recently unlocked apps (10 seconds)
            // Hanya aktif jika transisi berasal dari launcher kita sendiri atau aplikasi itu sendiri
            val isFromOurLauncher = previousPackage == null || previousPackage == this.packageName || previousPackage == packageName
            if (packageName == lastBypassPackage && (now - lastBypassTime) < 10000 && isFromOurLauncher) {
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
                    
                    val launchIntent = packageManager.getLaunchIntentForPackage(this.packageName)?.apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        putExtra("blockedPackageName", packageName)
                        putExtra("triggerBlockScreen", true)
                    }
                    startActivity(launchIntent)
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
                } else {
                    // Tampilkan overlay jika:
                    // 1. Buka link dari aplikasi eksternal (isLinkFromExternalApp == true), ATAU
                    // 2. Peluncuran baru / idle > 30 menit (!hasActiveSession)
                    Log.d("AppBlockService", "GHADHUL BASHAR: Triggered for $packageName (isExternalLink=$isLinkFromExternalApp, activeSession=$hasActiveSession)")
                    lastTriggeredPackage = packageName
                    lastTriggeredTime = now
                    MainActivity.notifyGhadhulBashar(packageName)
                    
                    val launchIntent = packageManager.getLaunchIntentForPackage(this.packageName)?.apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        putExtra("ghadhulBasharPackageName", packageName)
                        putExtra("triggerGhadhulBasharScreen", true)
                    }
                    startActivity(launchIntent)
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
}
