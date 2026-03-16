import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/translations.dart';
import '../quran/surah_list_screen.dart';
import 'accessibility_setup_screen.dart';
import '../../utils/page_transitions.dart';

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

  bool isNonProductive() {
    if (packageName == 'com.whatsapp' ||
        packageName == 'com.whatsapp.w4b' ||
        packageName == 'com.android.chrome' ||
        packageName == 'com.google.android.gm') {
      return false;
    }
    return category == 0 || category == 1 || category == 2 || category == 4;
  }
}

const _channel = MethodChannel('com.muslimlauncher/apps');

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  // ── Static caches ─────────────────────────────────────────────────────────
  static List<AppInfo>? _cache;
  static bool _preloading = false;
  static Completer<void>? _preloadCompleter;

  /// Icon cache: packageName → raw bytes. Persists for the lifetime of the app.
  static final Map<String, Uint8List> iconCache = {};

  // ── Preload ───────────────────────────────────────────────────────────────
  static Future<void> preload() async {
    if (_cache != null) return;
    if (_preloading) return _preloadCompleter?.future;

    _preloading = true;
    _preloadCompleter = Completer<void>();

    try {
      // 1) Fetch app list
      final List<dynamic> raw = await _channel.invokeMethod('getApps');
      final List<AppInfo> apps = await compute(_processApps, raw);
      _cache = apps;

      // 2) Batch-load all icons that are not yet cached
      final missing = apps
          .map((a) => a.packageName)
          .where((pkg) => !iconCache.containsKey(pkg))
          .toList();

      if (missing.isNotEmpty) {
        final Map<dynamic, dynamic> icons = await _channel.invokeMethod(
          'getAllAppIcons',
          {'packages': missing},
        );
        icons.forEach((pkg, bytes) {
          iconCache[pkg as String] = bytes as Uint8List;
        });
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
    return raw.map((a) => AppInfo.fromMap(a as Map<dynamic, dynamic>)).toList()
      ..sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
  }

  /// Invalidate only the app list. Icon cache is kept intact.
  static void invalidateAppsOnly() {
    _cache = null;
    _preloading = false;
  }

  /// Full invalidation (e.g. after install/uninstall where icons may change).
  static void invalidateFull() {
    _cache = null;
    _preloading = false;
    iconCache.clear();
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
      // Only invalidate app list; keep icon cache so icons don't reload.
      AppListScreen.invalidateAppsOnly();
      _fetchAndSet();
    }
  }

  Future<void> _fetchAndSet() async {
    await AppListScreen.preload();
    if (mounted) {
      final cache = AppListScreen.cachedApps;
      if (cache != null) {
        // Pre-decode all icons into Flutter's image cache in background
        for (var app in cache) {
          final bytes = AppListScreen.iconCache[app.packageName];
          if (bytes != null) {
            precacheImage(MemoryImage(bytes), context);
          }
        }
      }

      setState(() {
        _apps = AppListScreen.cachedApps;
        _updateFilter();
      });

      // Sync categories for auto-blocking
      final appState = Provider.of<AppState>(context, listen: false);
      final rawApps = await _channel.invokeMethod('getApps');
      appState.syncAppsWithCategories(rawApps);
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
    if (appState.isAppBlocked(app.packageName)) {
      _showBlockedDialog(app, appState);
    } else {
      _openApp(app.packageName);
    }
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
                    lang == 'en' ? 'Uninstall App' : 'Hapus Aplikasi',
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
                if (!context.read<AppState>().isAppBlocked(app.packageName))
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
                      lang == 'en' ? 'Block App' : 'Blokir Aplikasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<AppState>().toggleAppBlockedStatus(app.packageName);
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
        title: Text(lang == 'en' ? 'Uninstall App?' : 'Hapus Aplikasi?'),
        content: Text(
          lang == 'en'
              ? 'Are you sure you want to uninstall ${app.appName}?'
              : 'Apakah Anda yakin ingin menghapus ${app.appName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'en' ? 'Cancel' : 'Batal'),
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
            child: Text(lang == 'en' ? 'Uninstall' : 'Hapus'),
          ),
        ],
      ),
    );
  }

  void _showBlockedDialog(AppInfo app, AppState appState) {
    final lang = appState.languageCode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Translations.get(lang, 'non_productive')),
        content: Text(
          lang == 'en'
              ? 'This is a non-productive app. Spend 50 Points to open it?'
              : 'Aplikasi non-produktif. Gunakan 50 Poin untuk membuka?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (appState.points >= 50) {
                await appState.deductPoints(50);
                await appState.allowAppTemporarily(app.packageName);
                Navigator.pop(ctx);
                // Give a small delay for native service to sync bypass (1s is safer)
                await Future.delayed(const Duration(milliseconds: 1000));
                _openApp(app.packageName);
              } else {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  AppPageRoute(child: const SurahListScreen()),
                );
              }
            },
            child: Text(appState.points >= 50 ? (lang == 'en' ? 'Unlock (50 Pts)' : 'Buka (50 Poin)') : (lang == 'en' ? 'Read Quran' : 'Baca Quran')),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Only read language from AppState here; points badge uses Selector below.
    final lang = context.select<AppState, String>((s) => s.languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: lang == 'en' ? 'Search Apps...' : 'Cari Aplikasi...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _updateFilter();
                      });
                    },
                  )
                : const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.toLowerCase();
              _updateFilter();
            });
          },
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.security_rounded),
            onPressed: () => Navigator.push(context, AppPageRoute(child: const AccessibilitySetupScreen())),
            tooltip: lang == 'en' ? 'App Blocker Setup' : 'Setup Blokir',
          ),
          // Only this widget rebuilds when points change
          Selector<AppState, int>(
            selector: (_, s) => s.points,
            builder: (_, pts, child) => _PointsBadge(points: pts),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  lang == 'en'
                      ? 'Tap an icon to launch the app'
                      : 'Ketuk ikon untuk membuka aplikasi',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
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
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              lang == 'en' ? 'No apps found' : 'Aplikasi tidak ditemukan',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
      physics: const BouncingScrollPhysics(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final app = _filtered[index];
        return RepaintBoundary(
          child: Selector<AppState, bool>(
            selector: (context, state) => state.isAppBlocked(app.packageName),
            builder: (context, isBlocked, child) {
              return _AppTile(
                key: ValueKey(app.packageName),
                app: app,
                isBlocked: isBlocked,
                onTap: () => _onAppTap(app, context.read<AppState>()),
                onLongPress: () => _onAppLongPress(app),
              );
            },
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
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTile({
    super.key,
    required this.app,
    required this.isBlocked,
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
                _AppIcon(packageName: app.packageName, grayscale: isBlocked),
                if (isBlocked)
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
                Consumer<AppState>(
                  builder: (context, state, child) {
                    final remaining = state.getUnlockRemainingMinutes(app.packageName);
                    if (remaining <= 0) return const SizedBox.shrink();
                    
                    return Positioned(
                      left: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          "${remaining}m",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
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
                  color: isBlocked ? Colors.grey.shade500 : Colors.teal.shade900,
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

// ── _AppIcon (StatelessWidget – reads from static cache, no async setState) ──
class _AppIcon extends StatelessWidget {
  final String packageName;
  final bool grayscale;

  const _AppIcon({required this.packageName, this.grayscale = false});

  @override
  Widget build(BuildContext context) {
    final bytes = AppListScreen.iconCache[packageName];

    if (bytes == null) {
      // Fallback placeholder (rare: only if preload missed this package)
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.teal.shade50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.apps_rounded, size: 20, color: Colors.teal.shade200),
      );
    }

    Widget img = Image.memory(
      bytes,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

    if (grayscale) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            points.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
