package com.muslimlauncher.muslim_launcher_2

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.net.Uri
import android.provider.Settings
import android.text.TextUtils
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.muslimlauncher/apps"
    private val BLOCK_CHANNEL = "com.muslimlauncher/block"
    private val executor = Executors.newSingleThreadExecutor()

    companion object {
        private var blockChannel: MethodChannel? = null
        
        fun notifyAppBlocked(packageName: String) {
            blockChannel?.invokeMethod("onAppBlocked", mapOf("packageName" to packageName))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getApps" -> {
                    // Run on background thread to avoid blocking UI
                    executor.execute {
                        val apps = getInstalledApps()
                        runOnUiThread { result.success(apps) }
                    }
                }
                "getAllAppIcons" -> {
                    // Batch load all icons in one call on background thread
                    val packages = call.argument<List<String>>("packages")
                    if (packages != null) {
                        executor.execute {
                            val iconMap = mutableMapOf<String, ByteArray>()
                            for (pkg in packages) {
                                try {
                                    getAppIcon(pkg)?.let { iconMap[pkg] = it }
                                } catch (_: Exception) {}
                            }
                            runOnUiThread { result.success(iconMap) }
                        }
                    } else {
                        result.error("UNAVAILABLE", "Packages not provided.", null)
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
                "uninstallApp" -> {
                    val pkg = call.argument<String>("packageName")
                    if (pkg != null) { uninstallApp(pkg); result.success(null) }
                    else result.error("UNAVAILABLE", "Package name not provided.", null)
                }
                "isDefaultLauncher" -> {
                    result.success(isDefaultLauncher())
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
                else -> result.notImplemented()
            }
        }
        MainActivity.blockChannel = bc
        
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.getBooleanExtra("triggerBlockScreen", false)) {
            val blockedPackage = intent.getStringExtra("blockedPackageName") ?: ""
            notifyAppBlocked(blockedPackage)
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "$packageName/${AppBlockService::class.java.canonicalName}"
        val enabled = Settings.Secure.getInt(contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0)
        if (enabled == 1) {
            val settingValue = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            if (settingValue != null) {
                val splitter = TextUtils.SimpleStringSplitter(':')
                splitter.setString(settingValue)
                while (splitter.hasNext()) {
                    if (splitter.next().equals(service, ignoreCase = true)) return true
                }
            }
        }
        return false
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

    private fun openAppSettings(packageName: String) {
        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = android.net.Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun uninstallApp(packageName: String) {
        val intent = Intent(Intent.ACTION_DELETE).apply {
            data = android.net.Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }


    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
        val resolveInfo = packageManager.resolveActivity(intent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray? {
        val bitmap: Bitmap = when {
            drawable is BitmapDrawable -> drawable.bitmap
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && drawable is AdaptiveIconDrawable -> {
                Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888).also {
                    val canvas = Canvas(it)
                    drawable.setBounds(0, 0, 96, 96)
                    drawable.draw(canvas)
                }
            }
            else -> {
                val w = drawable.intrinsicWidth.takeIf { it in 1..96 } ?: 96
                val h = drawable.intrinsicHeight.takeIf { it in 1..96 } ?: 96
                Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
                    val canvas = Canvas(it)
                    drawable.setBounds(0, 0, w, h)
                    drawable.draw(canvas)
                }
            }
        }
        val stream = ByteArrayOutputStream()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            bitmap.compress(Bitmap.CompressFormat.WEBP_LOSSY, 70, stream)
        } else {
            @Suppress("DEPRECATION")
            bitmap.compress(Bitmap.CompressFormat.WEBP, 70, stream)
        }
        return stream.toByteArray()
    }
}
