import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/translations.dart';
import '../quran/surah_list_screen.dart';

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
    // Whitelist essential communication apps
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

  static List<AppInfo>? _cache;
  static bool _preloading = false;

  static Future<void> preload() async {
    if (_cache != null || _preloading) return;
    _preloading = true;
    try {
      final List<dynamic> raw = await _channel.invokeMethod('getApps');
      // Use compute to process large list in background
      final List<AppInfo> apps = await compute(_processApps, raw);
      _cache = apps;
    } catch (e) {
      // Error preloading apps
      _cache = [];
    } finally {
      _preloading = false;
    }
  }

  static List<AppInfo> _processApps(List<dynamic> raw) {
    return raw.map((a) => AppInfo.fromMap(a as Map<dynamic, dynamic>)).toList()
      ..sort(
        (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
      );
  }

  static void invalidate() {
    _cache = null;
    _preloading = false;
  }

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> with WidgetsBindingObserver {
  List<AppInfo>? _apps;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AppListScreen._cache != null) {
      _apps = AppListScreen._cache;
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
      // Refresh list whenever we return to the app
      // This catches uninstalls/installs that happened while we were in background
      AppListScreen.invalidate();
      _fetchAndSet();
    }
  }


  Future<void> _fetchAndSet() async {
    await AppListScreen.preload();
    if (mounted) setState(() => _apps = AppListScreen._cache);
  }

  Future<void> _openApp(String packageName) async {
    try {
      await _channel.invokeMethod('openApp', {'packageName': packageName});
    } catch (_) {
      // Failed to open app
    }
  }

  void _onAppTap(AppInfo app, AppState appState) {
    if (app.isNonProductive()) {
      _showBlockedDialog(app, appState);
    } else {
      _openApp(app.packageName);
    }
  }

  void _onAppLongPress(AppInfo app, AppState appState) {
    _showAppOptions(app, appState);
  }

  Future<void> _uninstallApp(String packageName) async {
    try {
      await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
      // Invalidate cache so next fetch gets fresh list
      AppListScreen.invalidate();
    } catch (e) {

      // Failed to uninstall app
    }
  }

  void _showAppOptions(AppInfo app, AppState appState) {
    final lang = appState.languageCode;
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
                // Extra margin for system navbar
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
            onPressed: () {
              if (appState.points >= 50) {
                appState.deductPoints(50);
                Navigator.pop(ctx);
                _openApp(app.packageName);
              } else {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SurahListScreen()),
                );
              }
            },
            child: Text(appState.points >= 50 ? 'Buka (50 Poin)' : 'Cari Poin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;

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
                      setState(() => _searchQuery = "");
                    },
                  )
                : const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val.toLowerCase());
          },
        ),

        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _PointsBadge(points: appState.points),
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
                : Builder(
                    builder: (context) {
                      final filtered = _apps!
                          .where(
                            (a) =>
                                a.appName.toLowerCase().contains(_searchQuery),
                          )
                          .toList();

                      if (filtered.isEmpty && _searchQuery.isNotEmpty) {
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
                                lang == 'en'
                                    ? 'No apps found'
                                    : 'Aplikasi tidak ditemukan',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final app = filtered[index];
                          final blocked = app.isNonProductive();
                          return RepaintBoundary(
                            child: _AppTile(
                              app: app,
                              blocked: blocked,
                              onTap: () => _onAppTap(app, appState),
                              onLongPress: () => _onAppLongPress(app, appState),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final AppInfo app;
  final bool blocked;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AppTile({
    required this.app,
    required this.blocked,
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
                  key: ValueKey('icon_${app.packageName}'),
                  packageName: app.packageName,
                  grayscale: blocked,
                ),
                if (blocked)
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
                  color: blocked ? Colors.grey.shade500 : Colors.teal.shade900,
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

class _AppIcon extends StatefulWidget {
  final String packageName;
  final bool grayscale;
  const _AppIcon({super.key, required this.packageName, this.grayscale = false});


  static final Map<String, Uint8List> _iconCache = {};

  @override
  State<_AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<_AppIcon> {
  Uint8List? _iconBytes;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    if (_AppIcon._iconCache.containsKey(widget.packageName)) {
      if (mounted) {
        setState(() => _iconBytes = _AppIcon._iconCache[widget.packageName]);
      }
      return;
    }

    try {
      final Uint8List? bytes = await _channel.invokeMethod('getAppIcon', {
        'packageName': widget.packageName,
      });
      if (bytes != null) {
        _AppIcon._iconCache[widget.packageName] = bytes;
        if (mounted) setState(() => _iconBytes = bytes);
      }
    } catch (e) {
      // Error loading icon
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_iconBytes == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.teal.shade50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.apps_rounded, size: 20, color: Colors.teal.shade200),
      );
    }
    Widget image = Image.memory(
      _iconBytes!,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );

    if (widget.grayscale) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: image,
      );
    }

    return image;
  }
}
