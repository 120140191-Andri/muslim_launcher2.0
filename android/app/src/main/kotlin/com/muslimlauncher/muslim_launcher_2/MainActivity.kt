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
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.muslimlauncher/apps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getApps" -> result.success(getInstalledApps())
                    "openApp" -> {
                        val pkg = call.argument<String>("packageName")
                        if (pkg != null) { openApp(pkg); result.success(null) }
                        else result.error("UNAVAILABLE", "Package name not provided.", null)
                    }
                    "isDefaultLauncher" -> result.success(isDefaultLauncher())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resultList = mutableListOf<Map<String, Any>>()
        for (resolveInfo in pm.queryIntentActivities(intent, 0)) {
            val packageName = resolveInfo.activityInfo.packageName
            if (packageName == context.packageName) continue

            val appName = resolveInfo.loadLabel(pm).toString()
            val iconBytes = drawableToByteArray(resolveInfo.loadIcon(pm)) ?: continue

            val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                resolveInfo.activityInfo.applicationInfo.category
            else -1

            resultList.add(
                mapOf(
                    "appName" to appName,
                    "packageName" to packageName,
                    "category" to category,
                    "icon" to iconBytes
                )
            )
        }
        return resultList
    }

    private fun openApp(packageName: String) {
        packageManager.getLaunchIntentForPackage(packageName)?.let { startActivity(it) }
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
                Bitmap.createBitmap(108, 108, Bitmap.Config.ARGB_8888).also {
                    val canvas = Canvas(it)
                    drawable.setBounds(0, 0, 108, 108)
                    drawable.draw(canvas)
                }
            }
            else -> {
                val w = drawable.intrinsicWidth.takeIf { it > 0 } ?: 108
                val h = drawable.intrinsicHeight.takeIf { it > 0 } ?: 108
                Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also {
                    val canvas = Canvas(it)
                    drawable.setBounds(0, 0, w, h)
                    drawable.draw(canvas)
                }
            }
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
