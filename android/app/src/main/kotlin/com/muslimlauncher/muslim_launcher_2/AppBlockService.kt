package com.muslimlauncher.muslim_launcher_2

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
        private var blockedPackages = Collections.synchronizedSet(mutableSetOf<String>())
        private var temporaryAllowedPackages = ConcurrentHashMap<String, Long>()
        
        // Transition Shield: Prevent loop during the first 10 seconds of unlock
        private var lastBypassPackage: String? = null
        private var lastBypassTime: Long = 0

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
            
            Log.d("AppBlockService", "ALLOW_TEMP: $pkg until $expiry (Shield ON)")
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
        loadTemporaryAllowed()
    }

    private val allowReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.muslimlauncher.ALLOW_PACKAGE") {
                val pkg = intent.getStringExtra("packageName")?.trim()?.lowercase()
                val duration = intent.getLongExtra("durationMillis", 3600000L)
                if (pkg != null) {
                    val now = System.currentTimeMillis()
                    val expiry = now + duration
                    temporaryAllowedPackages[pkg] = expiry
                    
                    // Activate Shield via Broadcast too
                    lastBypassPackage = pkg
                    lastBypassTime = now
                    
                    Log.d("AppBlockService", "BROADCAST RECEIVED: Allowed $pkg (Shield ON)")
                }
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // OPTIMIZATION: Only process window state changes (app switches)
        // This avoids processing every click, scroll, or focus event.
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        try {
            val eventPackage = event.packageName?.toString()?.trim()?.lowercase()
            
            // Priority 1: Event Source (if available, it's very accurate for the actual triggering window)
            val sourcePackage = event.source?.packageName?.toString()?.trim()?.lowercase()
            
            // Priority 2: rootInActiveWindow (Global foreground, but can be null)
            val activePackage = try { rootInActiveWindow?.packageName?.toString()?.trim()?.lowercase() } catch (e: Exception) { null }
            
            val packageName = sourcePackage ?: activePackage ?: eventPackage ?: return
            
            // Skip our own app
            if (packageName == this.packageName) return

            val now = System.currentTimeMillis()

            // 1. TRANSITION SHIELD (Highest Priority)
            // Immunity period for recently unlocked apps
            if (packageName == lastBypassPackage && (now - lastBypassTime) < 10000) {
                return 
            }

            // 2. BYPASS LIST CHECK
            val expiry = temporaryAllowedPackages[packageName]
            if (expiry != null) {
                if (now < expiry) {
                    return // ALLOWED
                } else {
                    temporaryAllowedPackages.remove(packageName)
                }
            }

            // 3. BLOCK CHECK
            if (blockedPackages.contains(packageName)) {
                Log.d("AppBlockService", "BLOCK: Detect $packageName")
                
                MainActivity.notifyAppBlocked(packageName)
                performGlobalAction(GLOBAL_ACTION_HOME)
                
                val launchIntent = packageManager.getLaunchIntentForPackage(this.packageName)?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("blockedPackageName", packageName)
                    putExtra("triggerBlockScreen", true)
                }
                startActivity(launchIntent)
            }
        } catch (e: Exception) {
            Log.e("AppBlockService", "Crash in onAccessibilityEvent: ${e.message}")
        }
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        super.onServiceConnected()
        loadBlockedPackages()
        
        // Register receiver for instant unlock signals
        val filter = IntentFilter("com.muslimlauncher.ALLOW_PACKAGE")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(allowReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(allowReceiver, filter)
        }
        
        Log.d("AppBlockService", "Accessibility Service Connected with Receiver (Protected)")
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(allowReceiver)
        } catch (e: Exception) {}
        super.onDestroy()
    }
}
