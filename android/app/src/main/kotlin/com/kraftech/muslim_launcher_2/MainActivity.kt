package com.kraftech.muslim_launcher_2

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.muslimlauncher/apps"
    private val BLOCK_CHANNEL = "com.muslimlauncher/block"
    private val threadPool = Executors.newFixedThreadPool(4)

    private var appsChannel: MethodChannel? = null

    private val packageReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            appsChannel?.invokeMethod("onAppListChanged", null)
        }
    }

    companion object {
        private var blockChannel: MethodChannel? = null
        private val uiHandler = android.os.Handler(android.os.Looper.getMainLooper())
        var pendingBlockedPackage: String? = null
        var pendingGhadhulBasharPackage: String? = null
        var pendingProhibitedPackage: String? = null

        private var lastNotifiedBlockPkg: String? = null
        private var lastNotifiedBlockTime: Long = 0L

        private var lastNotifiedGhadhulPkg: String? = null
        private var lastNotifiedGhadhulTime: Long = 0L

        private var lastNotifiedProhibitedPkg: String? = null
        private var lastNotifiedProhibitedTime: Long = 0L
        
        fun notifyAppBlocked(packageName: String) {
            val now = System.currentTimeMillis()
            val cleanPkg = packageName.trim().lowercase()
            if (cleanPkg.isEmpty()) return
            if (cleanPkg == lastNotifiedBlockPkg && (now - lastNotifiedBlockTime) < 2000L) {
                Log.d("MainActivity", "Duplicate notifyAppBlocked dropped for $cleanPkg")
                return
            }
            lastNotifiedBlockPkg = cleanPkg
            lastNotifiedBlockTime = now
            pendingBlockedPackage = cleanPkg
            uiHandler.post {
                blockChannel?.invokeMethod("onAppBlocked", mapOf("packageName" to cleanPkg))
            }
        }

        fun notifyGhadhulBashar(packageName: String) {
            val now = System.currentTimeMillis()
            val cleanPkg = packageName.trim().lowercase()
            if (cleanPkg.isEmpty()) return
            if (cleanPkg == lastNotifiedGhadhulPkg && (now - lastNotifiedGhadhulTime) < 2000L) {
                Log.d("MainActivity", "Duplicate notifyGhadhulBashar dropped for $cleanPkg")
                return
            }
            lastNotifiedGhadhulPkg = cleanPkg
            lastNotifiedGhadhulTime = now
            pendingGhadhulBasharPackage = cleanPkg
            uiHandler.post {
                blockChannel?.invokeMethod("onGhadhulBasharTriggered", mapOf("packageName" to cleanPkg))
            }
        }

        fun notifyAppProhibited(packageName: String) {
            val now = System.currentTimeMillis()
            val cleanPkg = packageName.trim().lowercase()
            if (cleanPkg.isEmpty()) return
            if (cleanPkg == lastNotifiedProhibitedPkg && (now - lastNotifiedProhibitedTime) < 2000L) {
                Log.d("MainActivity", "Duplicate notifyAppProhibited dropped for $cleanPkg")
                return
            }
            lastNotifiedProhibitedPkg = cleanPkg
            lastNotifiedProhibitedTime = now
            pendingProhibitedPackage = cleanPkg
            uiHandler.post {
                blockChannel?.invokeMethod("onProhibitedAppTriggered", mapOf("packageName" to cleanPkg))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        val channel = appsChannel!!

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_FULLY_REMOVED)
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addDataScheme("package")
        }
        registerReceiver(packageReceiver, filter)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getApps" -> {
                    // Run on threadPool background thread to avoid blocking UI
                    threadPool.execute {
                        val apps = getInstalledApps()
                        runOnUiThread { result.success(apps) }
                    }
                }
                "getAllAppIcons" -> {
                    val packages = call.argument<List<String>>("packages")
                    if (packages != null && packages.isNotEmpty()) {
                        threadPool.execute {
                            val iconMap = java.util.concurrent.ConcurrentHashMap<String, ByteArray>()
                            val pm = packageManager
                            val countDownLatch = java.util.concurrent.CountDownLatch(packages.size)
                            for (pkg in packages) {
                                threadPool.execute {
                                    try {
                                        val iconDrawable = pm.getApplicationIcon(pkg)
                                        val iconBytes = drawableToByteArray(iconDrawable)
                                        if (iconBytes != null && iconBytes.isNotEmpty()) {
                                            iconMap[pkg] = iconBytes
                                        }
                                    } catch (_: Exception) {} finally {
                                        countDownLatch.countDown()
                                    }
                                }
                            }
                            try {
                                countDownLatch.await(15, java.util.concurrent.TimeUnit.SECONDS)
                            } catch (_: Exception) {}
                            runOnUiThread { result.success(iconMap) }
                        }
                    } else {
                        runOnUiThread { result.success(emptyMap<String, ByteArray>()) }
                    }
                }
                "getAppIcon" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) result.success(getAppIcon(pkg))
                    else result.error("UNAVAILABLE", "Package name not provided.", null)
                }
                "openApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) { openApp(pkg); result.success(null) }
                    else result.error("UNAVAILABLE", "Package name not provided.", null)
                }
                "openAppSettings" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) { openAppSettings(pkg); result.success(null) }
                    else result.error("UNAVAILABLE", "Package name not provided.", null)
                }
                "openAutostartSettings" -> {
                    openAutostartSettings()
                    result.success(true)
                }
                "uninstallApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) { uninstallApp(pkg); result.success(null) }
                    else result.error("UNAVAILABLE", "Package name not provided.", null)
                }
                "isDefaultLauncher" -> {
                    result.success(isDefaultLauncher())
                }
                "openPhoneApp" -> {
                    openPhoneApp()
                    result.success(true)
                }
                "getDeviceInfo" -> {
                    result.success(
                        mapOf(
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "sdkInt" to Build.VERSION.SDK_INT
                        )
                    )
                }
                "getAppStoragePath" -> {
                    result.success(context.filesDir.absolutePath)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        val bc = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BLOCK_CHANNEL)
        bc.setMethodCallHandler { call, result ->
            when (call.method) {
                "setBlockedApps" -> {
                    val apps = call.argument<List<String>>("packages") ?: emptyList()
                    Log.d("MainActivity", "Syncing blocked apps: ${apps.joinToString(", ")}")
                    AppBlockService.updateBlockedPackages(this, apps)
                    result.success(true)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "allowAppTemporarily" -> {
                    val args = call.arguments as? Map<*, *>
                    val pkg = args?.get("packageName") as? String
                    val durationRaw = args?.get("durationMillis")
                    val duration = when (durationRaw) {
                        is Number -> durationRaw.toLong()
                        else -> 3600000L
                    }

                    if (pkg != null) {
                        AppBlockService.allowTemporarily(this, pkg, duration)
                        
                        // Send instant broadcast to active service
                        val intent = Intent("com.muslimlauncher.ALLOW_PACKAGE").apply {
                            setPackage(packageName)
                            putExtra("packageName", pkg)
                            putExtra("durationMillis", duration)
                        }
                        sendBroadcast(intent)
                        
                        result.success(true)
                    } else {
                        result.error("ERROR", "Package name missing", null)
                    }
                }
                "setGhadhulBasharPackages" -> {
                    val apps = call.argument<List<String>>("packages") ?: emptyList()
                    AppBlockService.updateGhadhulBasharPackages(this, apps)
                    result.success(true)
                }
                "allowGhadhulBasharSession" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        AppBlockService.allowGhadhulBasharSession(pkg)
                        val intent = Intent("com.muslimlauncher.ALLOW_GHADHUL_BASHAR").apply {
                            setPackage(packageName)
                            putExtra("packageName", pkg)
                        }
                        sendBroadcast(intent)
                        result.success(true)
                    } else {
                        result.error("ERROR", "Package name missing", null)
                    }
                }
                "resetGhadhulBasharSession" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) {
                        AppBlockService.resetGhadhulBasharSession(pkg)
                        val intent = Intent("com.muslimlauncher.RESET_GHADHUL_BASHAR").apply {
                            setPackage(packageName)
                            putExtra("packageName", pkg)
                        }
                        sendBroadcast(intent)
                        result.success(true)
                    } else {
                        result.error("ERROR", "Package name missing", null)
                    }
                }
                "setProhibitedPackages" -> {
                    val apps = call.argument<List<String>>("packages") ?: emptyList()
                    AppBlockService.updateProhibitedPackages(this, apps)
                    result.success(true)
                }
                "getPendingInitialBlock" -> {
                    val resultData = mapOf(
                        "blocked" to pendingBlockedPackage,
                        "ghadhul" to pendingGhadhulBasharPackage,
                        "prohibited" to pendingProhibitedPackage
                    )
                    pendingBlockedPackage = null
                    pendingGhadhulBasharPackage = null
                    pendingProhibitedPackage = null
                    result.success(resultData)
                }
                else -> result.notImplemented()
            }
        }
        MainActivity.blockChannel = bc
        
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        val isOverlayIntent = intent.getBooleanExtra("triggerBlockScreen", false) ||
            intent.getBooleanExtra("triggerProhibitedScreen", false) ||
            intent.getBooleanExtra("triggerGhadhulBasharScreen", false)

        handleIntent(intent)

        if (intent.action == Intent.ACTION_MAIN && intent.hasCategory(Intent.CATEGORY_HOME) && !isOverlayIntent) {
            val hasPendingBlock = !pendingBlockedPackage.isNullOrEmpty() ||
                !pendingProhibitedPackage.isNullOrEmpty() ||
                !pendingGhadhulBasharPackage.isNullOrEmpty()
            if (!hasPendingBlock) {
                appsChannel?.invokeMethod("onHomePressed", null)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Replay any pending block events that arrived while the activity was paused.
        // The accessibility service may have set pendingBlockedPackage etc. while we were
        // in background — now that we're back, deliver them to Flutter.
        replayPendingEvents()
    }

    private fun replayPendingEvents() {
        val bc = blockChannel ?: return
        pendingProhibitedPackage?.let { pkg ->
            if (pkg.isNotEmpty()) {
                lastNotifiedProhibitedPkg = null
                lastNotifiedProhibitedTime = 0L
                uiHandler.post {
                    bc.invokeMethod("onProhibitedAppTriggered", mapOf("packageName" to pkg))
                }
            }
        }
        pendingBlockedPackage?.let { pkg ->
            if (pkg.isNotEmpty() && pendingProhibitedPackage.isNullOrEmpty()) {
                lastNotifiedBlockPkg = null
                lastNotifiedBlockTime = 0L
                uiHandler.post {
                    bc.invokeMethod("onAppBlocked", mapOf("packageName" to pkg))
                }
            }
        }
        pendingGhadhulBasharPackage?.let { pkg ->
            if (pkg.isNotEmpty() && pendingProhibitedPackage.isNullOrEmpty() && pendingBlockedPackage.isNullOrEmpty()) {
                lastNotifiedGhadhulPkg = null
                lastNotifiedGhadhulTime = 0L
                uiHandler.post {
                    bc.invokeMethod("onGhadhulBasharTriggered", mapOf("packageName" to pkg))
                }
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.getBooleanExtra("triggerBlockScreen", false)) {
            val blockedPackage = intent.getStringExtra("blockedPackageName") ?: ""
            intent.removeExtra("triggerBlockScreen")
            intent.removeExtra("blockedPackageName")
            if (blockedPackage.isNotEmpty()) {
                // Reset debounce so this intent-based trigger is never dropped
                // (the first call from onAccessibilityEvent may have been dropped
                // because blockChannel was null while Flutter was in background)
                lastNotifiedBlockPkg = null
                lastNotifiedBlockTime = 0L
                notifyAppBlocked(blockedPackage)
            }
        }
        if (intent.getBooleanExtra("triggerGhadhulBasharScreen", false)) {
            val ghadhulPackage = intent.getStringExtra("ghadhulBasharPackageName") ?: ""
            intent.removeExtra("triggerGhadhulBasharScreen")
            intent.removeExtra("ghadhulBasharPackageName")
            if (ghadhulPackage.isNotEmpty()) {
                lastNotifiedGhadhulPkg = null
                lastNotifiedGhadhulTime = 0L
                notifyGhadhulBashar(ghadhulPackage)
            }
        }
        if (intent.getBooleanExtra("triggerProhibitedScreen", false)) {
            val prohibitedPackage = intent.getStringExtra("prohibitedPackageName") ?: ""
            intent.removeExtra("triggerProhibitedScreen")
            intent.removeExtra("prohibitedPackageName")
            if (prohibitedPackage.isNotEmpty()) {
                lastNotifiedProhibitedPkg = null
                lastNotifiedProhibitedTime = 0L
                notifyAppProhibited(prohibitedPackage)
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        return try {
            val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as? android.view.accessibility.AccessibilityManager ?: return false
            val enabledServices = am.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_ALL_MASK) ?: emptyList()
            
            // 1. Check via AccessibilityManager (Most reliable)
            for (service in enabledServices) {
                if (service.id.contains(packageName)) return true
            }

            // 2. Fallback: Detailed check via Settings.Secure
            val expectedService = "$packageName/${AppBlockService::class.java.name}"
            val enabled = Settings.Secure.getInt(contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0)
            if (enabled == 1) {
                val settingValue = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
                if (settingValue != null) {
                    val splitter = TextUtils.SimpleStringSplitter(':')
                    splitter.setString(settingValue)
                    while (splitter.hasNext()) {
                        val componentName = splitter.next()
                        if (componentName.equals(expectedService, ignoreCase = true) || 
                            componentName.contains(packageName)) {
                            return true
                        }
                    }
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }



    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resultList = mutableListOf<Map<String, Any>>()
        for (resolveInfo in pm.queryIntentActivities(intent, 0)) {
            val activityInfo = resolveInfo.activityInfo
            val packageName = activityInfo.packageName
            if (packageName == context.packageName) continue

            val appName = resolveInfo.loadLabel(pm).toString()
            val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                activityInfo.applicationInfo.category
            else -1

            resultList.add(
                mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "category" to category
                )
            )
        }
        return resultList
    }

    private fun getAppIcon(packageName: String): ByteArray? {
        return try {
            val pm = packageManager
            val icon = pm.getApplicationIcon(packageName)
            drawableToByteArray(icon)
        } catch (e: Exception) {
            null
        }
    }

    private fun openApp(packageName: String) {
        packageManager.getLaunchIntentForPackage(packageName)?.let { 
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(it) 
        }
    }

    private fun openPhoneApp() {
        val dialerPackages = listOf(
            "com.google.android.dialer",
            "com.samsung.android.dialer",
            "com.sec.android.app.dialer",
            "com.android.dialer",
            "com.android.phone"
        )

        for (pkg in dialerPackages) {
            try {
                val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(launchIntent)
                    return
                }
            } catch (_: Exception) {}
        }

        val intents = listOf(
            Intent(Intent.ACTION_DIAL),
            Intent(Intent.ACTION_VIEW, Uri.parse("tel:")),
            Intent("android.intent.action.CALL_BUTTON")
        )

        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return
            } catch (e: Exception) {
                android.util.Log.e("MuslimLauncher", "Failed to start phone intent: ${e.message}")
            }
        }
    }

    private fun openAppSettings(packageName: String) {
        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = android.net.Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun openAutostartSettings() {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val intents = mutableListOf<Intent>()

        when {
            manufacturer.contains("xiaomi") || manufacturer.contains("poco") || manufacturer.contains("redmi") || manufacturer.contains("blackshark") -> {
                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")))
                intents.add(Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity")))
            }
            manufacturer.contains("oppo") || manufacturer.contains("oneplus") || manufacturer.contains("realme") -> {
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")))
            }
            manufacturer.contains("vivo") || manufacturer.contains("iqoo") -> {
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")))
                intents.add(Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManagerActivity")))
            }
            manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")))
                intents.add(Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")))
            }
            manufacturer.contains("samsung") -> {
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.looper", "com.samsung.android.sm.ui.battery.BatteryActivity")))
                intents.add(Intent().setComponent(ComponentName("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity")))
            }
            manufacturer.contains("infinix") || manufacturer.contains("tecno") || manufacturer.contains("itel") || manufacturer.contains("transsion") -> {
                intents.add(Intent().setComponent(ComponentName("com.transsion.phonemanager", "com.transsion.phonemanager.settings.AutoStartManagementActivity")))
            }
            manufacturer.contains("asus") -> {
                intents.add(Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity")))
            }
        }

        // Try requesting ignore battery optimization directly
        try {
            intents.add(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            })
        } catch (_: Exception) {}

        // Standard Battery optimization settings fallback
        intents.add(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))

        // Application details settings fallback
        intents.add(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        })

        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return
            } catch (_: Exception) {
                // Try next intent fallback
            }
        }
    }

    private fun uninstallApp(packageName: String) {
        val intent = Intent(Intent.ACTION_DELETE).apply {
            data = android.net.Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }


    private fun isDefaultLauncher(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
            val resolveInfo = packageManager.resolveActivity(intent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY)
            resolveInfo?.activityInfo?.packageName == packageName
        } catch (_: Exception) {
            false
        }
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray? {
        val size = 96
        return try {
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)

            val stream = ByteArrayOutputStream()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                bitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, 85, stream)
            } else {
                @Suppress("DEPRECATION")
                bitmap.compress(Bitmap.CompressFormat.WEBP, 85, stream)
            }
            val result = stream.toByteArray()
            bitmap.recycle()
            result
        } catch (e: Exception) {
            try {
                val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, size, size)
                drawable.draw(canvas)
                val stream = ByteArrayOutputStream()
                bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
                val result = stream.toByteArray()
                bmp.recycle()
                result
            } catch (_: Exception) {
                null
            }
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(packageReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
