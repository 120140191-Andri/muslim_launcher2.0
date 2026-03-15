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
    if (packageName == 'com.whatsapp' || packageName == 'com.whatsapp.w4b') {
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
      debugPrint("Error preloading apps: $e");
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

class _AppListScreenState extends State<AppListScreen> {
  List<AppInfo>? _apps;

  @override
  void initState() {
    super.initState();
    if (AppListScreen._cache != null) {
      _apps = AppListScreen._cache;
    } else {
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
    } on PlatformException catch (e) {
      debugPrint('Failed to open app: ${e.message}');
    }
  }

  void _onAppTap(AppInfo app, AppState appState) {
    if (app.isNonProductive()) {
      _showBlockedDialog(app, appState);
    } else {
      _openApp(app.packageName);
    }
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
        title: Text(lang == 'en' ? 'All Apps' : 'Semua Aplikasi'),
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
                  color: Colors.white.withOpacity(0.6),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  lang == 'en'
                      ? 'Tap an icon to launch the app'
                      : 'Ketuk ikon untuk membuka aplikasi',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _apps == null
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _apps!.length,
                    itemBuilder: (context, index) {
                      final app = _apps![index];
                      final blocked = app.isNonProductive();
                      return _AppTile(
                        app: app,
                        blocked: blocked,
                        onTap: () => _onAppTap(app, appState),
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

  const _AppTile({
    required this.app,
    required this.blocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _AppIcon(packageName: app.packageName),
                if (blocked)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            app.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.teal.shade900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
        color: Colors.white.withOpacity(0.2),
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
  const _AppIcon({required this.packageName});

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
      if (mounted)
        setState(() => _iconBytes = _AppIcon._iconCache[widget.packageName]);
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
      debugPrint("Error loading icon for ${widget.packageName}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_iconBytes == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.apps_rounded, size: 20, color: Colors.grey.shade300),
      );
    }
    return Image.memory(
      _iconBytes!,
      width: 44,
      height: 44,
      filterQuality: FilterQuality.low, // Pertahankan performa scroll
    );
  }
}
