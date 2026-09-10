import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/translations.dart';
import '../../widgets/language_selection_dialog.dart';

// ── AppInfo model ────────────────────────────────────────────────────────────
class AppInfo {
  final String appName;
  final String packageName;
  final int category;

  AppInfo({
    required this.appName,
    required this.packageName,
    required this.category,
  });

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      appName: map['appName'] as String,
      packageName: map['packageName'] as String,
      category: map['category'] as int? ?? -1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'category': category,
    };
  }

  bool isNonProductive() {
    return AppState.isNonProductiveApp(packageName, appName, category);
  }
}

const _channel = MethodChannel('com.muslimlauncher/apps');

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  // ── Static caches ─────────────────────────────────────────────────────────
  static List<AppInfo>? _cache;
  static bool _preloading = false;
  static Completer<void>? _preloadCompleter;
  static String? _storagePath;
  static SharedPreferences? _prefs;

  /// Icon cache: packageName → raw bytes. Persists for the lifetime of the app.
  static final Map<String, Uint8List> iconCache = {};
  static final Set<String> _pendingIconRequests = {};

  /// On-demand self-healing loader for any single missing icon
  static Future<Uint8List?> loadIconOnDemand(String packageName) async {
    if (iconCache.containsKey(packageName)) return iconCache[packageName];
    if (_pendingIconRequests.contains(packageName)) return null;
    _pendingIconRequests.add(packageName);
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'getAppIcon',
        {'packageName': packageName},
      );
      if (bytes != null && bytes.isNotEmpty) {
        iconCache[packageName] = bytes;
        if (_storagePath != null) {
          try {
            final file = File('$_storagePath/app_icons/$packageName.bin');
            file.writeAsBytes(bytes, flush: false).catchError((_) => file);
          } catch (_) {}
        }
        return bytes;
      }
    } catch (e) {
      debugPrint("loadIconOnDemand error for $packageName: $e");
    } finally {
      _pendingIconRequests.remove(packageName);
    }
    return null;
  }

  /// Fast hydration from persistent disk storage into memory on startup (takes < 15ms)
  static Future<void> initFromDisk(SharedPreferences prefs) async {
    _prefs = prefs;
    try {
      // 1) Hydrate app list from SharedPreferences
      final cachedAppsJson = prefs.getString('cached_installed_apps');
      if (cachedAppsJson != null && cachedAppsJson.isNotEmpty) {
        try {
          final decoded = json.decode(cachedAppsJson) as List;
          _cache = decoded
              .map((e) => AppInfo.fromMap(e as Map<dynamic, dynamic>))
              .toList();
        } catch (_) {}
      }

      // 2) Hydrate icon bytes from internal app storage
      try {
        final resPath = await _channel.invokeMethod('getAppStoragePath');
        final path = resPath is String ? resPath : null;
        if (path != null && path.isNotEmpty) {
          _storagePath = path;
          final iconDir = Directory('$path/app_icons');
          if (await iconDir.exists()) {
            final entities = iconDir.listSync();
            for (final entity in entities) {
              if (entity is File && entity.path.endsWith('.bin')) {
                final filename = entity.uri.pathSegments.last;
                final pkg = filename.substring(0, filename.length - 4);
                if (pkg.isNotEmpty && !iconCache.containsKey(pkg)) {
                  try {
                    final bytes = entity.readAsBytesSync();
                    if (bytes.isNotEmpty) {
                      iconCache[pkg] = bytes;
                    }
                  } catch (_) {}
                }
              }
            }
          } else {
            await iconDir.create(recursive: true);
          }
        }
      } catch (e) {
        debugPrint("Icon disk hydration error: $e");
      }
    } catch (e) {
      debugPrint("initFromDisk error: $e");
    }
  }

  // ── Preload ───────────────────────────────────────────────────────────────
  static Future<void> preload({
    VoidCallback? onProgress,
    Function(List<dynamic>)? onRawAppsFetched,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null && iconCache.isNotEmpty) return;
    if (_preloading) return _preloadCompleter!.future;

    _preloading = true;
    _preloadCompleter = Completer<void>();

    try {
      // Ensure storage path is known
      if (_storagePath == null) {
        try {
          final resPath = await _channel.invokeMethod('getAppStoragePath');
          final path = resPath is String ? resPath : null;
          if (path != null && path.isNotEmpty) {
            _storagePath = path;
            final iconDir = Directory('$path/app_icons');
            if (!await iconDir.exists()) await iconDir.create(recursive: true);
          }
        } catch (_) {}
      }

      // 1) Fetch app list immediately
      final rawRes = await _channel.invokeMethod('getApps');
      final List<dynamic> raw = rawRes is List ? rawRes : <dynamic>[];
      onRawAppsFetched?.call(raw);
      final List<AppInfo> apps = (raw.length > 200)
          ? await compute(_processApps, raw)
          : _processApps(raw);
      _cache = apps;

      // Persist app list to SharedPreferences
      if (_prefs != null) {
        _prefs!.setString(
          'cached_installed_apps',
          json.encode(apps.map((a) => a.toMap()).toList()),
        );
      }

      onProgress?.call();

      // 2) Clean up uninstalled apps from icon cache and disk
      iconCache.removeWhere((pkg, _) => !apps.any((a) => a.packageName == pkg));
      if (_storagePath != null) {
        try {
          final iconDir = Directory('$_storagePath/app_icons');
          if (iconDir.existsSync()) {
            final installedSet = apps.map((a) => a.packageName).toSet();
            for (final entity in iconDir.listSync()) {
              if (entity is File && entity.path.endsWith('.bin')) {
                final filename = entity.uri.pathSegments.last;
                final pkg = filename.substring(0, filename.length - 4);
                if (!installedSet.contains(pkg)) {
                  entity.delete().catchError((_) => entity);
                }
              }
            }
          }
        } catch (_) {}
      }

      // 3) Batch-load all missing icons using multi-threaded native pool
      final missing = apps
          .map((a) => a.packageName)
          .where((pkg) => !iconCache.containsKey(pkg))
          .toList();

      if (missing.isNotEmpty) {
        for (var i = 0; i < missing.length; i += 50) {
          final end = (i + 50 < missing.length) ? i + 50 : missing.length;
          final batch = missing.sublist(i, end);

          try {
            final resIcons = await _channel.invokeMethod(
              'getAllAppIcons',
              {'packages': batch},
            );
            if (resIcons is Map) {
              resIcons.forEach((pkg, bytes) {
                if (pkg is String && bytes is Uint8List) {
                  iconCache[pkg] = bytes;

                  // Save to persistent disk storage asynchronously
                  if (_storagePath != null) {
                    try {
                      final file = File('$_storagePath/app_icons/$pkg.bin');
                      file.writeAsBytes(bytes, flush: false).catchError((_) => file);
                    } catch (_) {}
                  }
                }
              });
              onProgress?.call();
            }
          } catch (e) {
            debugPrint("Batch icon load error at $i: $e");
          }
        }
      }
    } catch (_) {
      _cache ??= [];
    } finally {
      _preloading = false;
      _preloadCompleter?.complete();
      _preloadCompleter = null;
    }
  }

  static List<AppInfo> _processApps(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((a) => AppInfo.fromMap(a))
        .toList()
      ..sort(
        (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
      );
  }

  /// Invalidate only the app list. Icon cache is kept intact.
  static void invalidateAppsOnly() {
    _preloading = false;
  }

  /// Invalidate apps for re-fetching without abruptly clearing memory cache.
  static void invalidateFull() {
    _preloading = false;
  }

  static List<AppInfo>? get cachedApps => _cache;

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

// ── State ────────────────────────────────────────────────────────────────────
class _AppListScreenState extends State<AppListScreen>
    with WidgetsBindingObserver {
  List<AppInfo>? _apps;
  List<AppInfo> _filtered = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (AppListScreen._cache != null) {
      _apps = AppListScreen._cache;
      _filtered = _apps!;
    } else {
      _fetchAndSet();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only re-fetch if cache was invalidated (e.g. after install/uninstall).
      // Native 'onAppListChanged' callback handles invalidation automatically.
      if (AppListScreen._cache == null) {
        _fetchAndSet();
      }
    }
  }

  Future<void> _fetchAndSet() async {
    final appState = Provider.of<AppState>(context, listen: false);

    await AppListScreen.preload(
      onProgress: () {
        if (mounted) {
          setState(() {
            _apps = AppListScreen.cachedApps;
            _updateFilter();
          });
        }
      },
      onRawAppsFetched: (raw) {
        appState.syncAppsWithCategories(raw);
      },
    );

    if (mounted) {
      setState(() {
        _apps = AppListScreen.cachedApps;
        _updateFilter();
      });
    }
  }

  void _updateFilter() {
    if (_apps == null) {
      _filtered = [];
      return;
    }
    if (_searchQuery.isEmpty) {
      _filtered = _apps ?? [];
    } else {
      _filtered = (_apps ?? [])
          .where((a) => a.appName.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  Future<void> _openApp(String packageName) async {
    try {
      await _channel.invokeMethod('openApp', {'packageName': packageName});
    } catch (_) {}
  }

  void _onAppTap(AppInfo app, AppState appState) {
    if (appState.isAppProhibited(app.packageName, app.appName)) {
      appState.setProhibitedPackage(app.packageName);
      return;
    }
    if (appState.isAppBlocked(app.packageName)) {
      appState.setBlockedPackage(app.packageName);
      return;
    }
    if (AppState.shouldShowGhadhulBasharReminder(app.packageName, app.appName, appState.languageCode)) {
      appState.setGhadhulBasharPackage(app.packageName);
      return;
    }
    _openApp(app.packageName);
  }

  void _onAppLongPress(AppInfo app) {
    _showAppOptions(app);
  }

  Future<void> _uninstallApp(String packageName) async {
    try {
      await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
      AppListScreen.invalidateFull();
    } catch (_) {}
  }

  void _showAppOptions(AppInfo app) {
    final lang = context.read<AppState>().languageCode;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.red.shade700,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    Translations.get(lang, 'uninstall_app'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.red.shade900,
                    ),
                  ),
                  subtitle: Text(
                    app.appName,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmUninstall(app, lang);
                  },
                ),
                if (!context.read<AppState>().isAppBlocked(app.packageName) &&
                    !AppState.isProductiveApp(app.packageName, app.appName, app.category))
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.teal.shade700,
                        size: 28,
                      ),
                    ),
                    title: Text(
                      Translations.get(lang, 'non_productive'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<AppState>().toggleAppBlockedStatus(
                        app.packageName,
                        category: app.category,
                        appName: app.appName,
                      );
                    },
                  ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmUninstall(AppInfo app, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Translations.get(lang, 'uninstall_app')),
        content: Text(
          Translations.get(lang, 'uninstall_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translations.get(lang, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _uninstallApp(app.packageName);
            },
            child: Text(Translations.get(lang, 'uninstall')),
          ),
        ],
      ),
    );
  }

  Future<void> _openSupportDeveloperUrl() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final url = appState.supportUrl;
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: url,
      );
      await intent.launch();
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Only read language from AppState here; points badge uses Selector below.
    final lang = context.select<AppState, String>((s) => s.languageCode);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: 16,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
            cursorColor: colorScheme.primary,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: Translations.get(lang, 'search_apps'),
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
              border: InputBorder.none,
              isDense: true,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      iconSize: 18,
                      icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _updateFilter();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
                _updateFilter();
              });
            },
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 2,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.language_rounded, size: 22, color: colorScheme.onSurfaceVariant),
            tooltip: Translations.get(lang, 'language_selection'),
            onPressed: () => LanguageSelectionDialog.show(context),
          ),
          Selector<AppState, int>(
            selector: (_, s) => s.points,
            builder: (_, pts, child) => _PointsBadge(points: pts),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Support Dev Banner (Saran 1: Sleek Compact Hero Pill)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F5E3B),
                  Color(0xFF094027),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D5C3A).withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openSupportDeveloperUrl,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.coffee_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Translations.get(lang, 'support_feature_request'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              Translations.get(lang, 'free_ad_free_app'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _apps == null
                ? const Center(child: CircularProgressIndicator())
                : _buildGrid(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(String lang) {
    if (_filtered.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get(lang, 'no_apps_found'),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final appState = Provider.of<AppState>(context);
    final blocked = appState.blockedApps;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      cacheExtent: 50,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final app = _filtered[index];
        final isBlocked = blocked.contains(app.packageName);
        final isProhibited =
            appState.isAppProhibited(app.packageName, app.appName);
        final remainingMins =
            appState.getUnlockRemainingMinutes(app.packageName);

        return RepaintBoundary(
          child: _AppTile(
            key: ValueKey(app.packageName),
            app: app,
            isBlocked: isBlocked,
            isProhibited: isProhibited,
            remainingMinutes: remainingMins,
            onTap: () => _onAppTap(app, appState),
            onLongPress: () => _onAppLongPress(app),
          ),
        );
      },
    );
  }
}

// ── _AppTile ─────────────────────────────────────────────────────────────────
class _AppTile extends StatelessWidget {
  final AppInfo app;
  final bool isBlocked;
  final bool isProhibited;
  final int remainingMinutes;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTile({
    super.key,
    required this.app,
    required this.isBlocked,
    this.isProhibited = false,
    this.remainingMinutes = 0,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _AppIcon(
                  packageName: app.packageName,
                  grayscale: isBlocked || isProhibited,
                ),
                if (isProhibited)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFE11D48).withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  )
                else if (isBlocked)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                // Timer badge
                if (!isProhibited && remainingMinutes > 0)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        "${remainingMinutes}m",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                app.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isBlocked
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _AppIcon (StatefulWidget with auto on-demand fetch fallback) ─────────────
class _AppIcon extends StatefulWidget {
  final String packageName;
  final bool grayscale;

  const _AppIcon({required this.packageName, this.grayscale = false});

  @override
  State<_AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<_AppIcon> {
  @override
  void initState() {
    super.initState();
    if (!AppListScreen.iconCache.containsKey(widget.packageName)) {
      AppListScreen.loadIconOnDemand(widget.packageName).then((bytes) {
        if (mounted && bytes != null) {
          setState(() {});
        }
      });
    }
  }

  static const ColorFilter _grayscaleFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final bytes = AppListScreen.iconCache[widget.packageName];
    final colorScheme = Theme.of(context).colorScheme;

    if (bytes == null || bytes.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.apps_rounded, size: 22, color: colorScheme.primary),
      );
    }

    Widget img = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.memory(
        bytes,
        width: 48,
        height: 48,
        cacheWidth: 96,
        cacheHeight: 96,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.apps_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
          );
        },
      ),
    );

    if (widget.grayscale) {
      img = ColorFiltered(
        colorFilter: _grayscaleFilter,
        child: img,
      );
    }

    return img;
  }
}

// ── _PointsBadge ─────────────────────────────────────────────────────────────
class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: colorScheme.onTertiaryContainer, size: 16),
          const SizedBox(width: 4),
          Text(
            points.toString(),
            style: TextStyle(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
