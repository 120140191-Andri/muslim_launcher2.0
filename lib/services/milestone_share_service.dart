import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MilestoneShareService {
  MilestoneShareService._();

  /// Captures a [GlobalKey] RepaintBoundary as high-resolution PNG byte data.
  static Future<Uint8List?> captureBoundaryAsPng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('MilestoneShareService.captureBoundaryAsPng error: $e');
      return null;
    }
  }

  /// Saves PNG bytes into a temporary cache file and invokes the native Android Share Sheet.
  /// Fully compliant with Zero Storage Permissions via Android FileProvider.
  static Future<bool> shareMilestoneCard({
    required GlobalKey boundaryKey,
    required String shareText,
    String fileNamePrefix = 'muslim_launcher_milestone',
  }) async {
    try {
      final bytes = await captureBoundaryAsPng(boundaryKey);
      if (bytes == null || bytes.isEmpty) return false;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/${fileNamePrefix}_$timestamp.png');
      await file.writeAsBytes(bytes, flush: true);

      final xFile = XFile(file.path, mimeType: 'image/png');
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          files: [xFile],
        ),
      );
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('MilestoneShareService.shareMilestoneCard error: $e');
      return false;
    }
  }

  /// Saves PNG bytes directly to public device Pictures without requiring storage permissions
  /// on Android 10+ (API 29+) via Scoped Storage.
  static Future<String?> saveMilestoneToGallery({
    required GlobalKey boundaryKey,
    String fileNamePrefix = 'muslim_launcher_milestone',
  }) async {
    try {
      final bytes = await captureBoundaryAsPng(boundaryKey);
      if (bytes == null || bytes.isEmpty) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${fileNamePrefix}_$timestamp.png';

      Directory? targetDir;

      // 1. Try public Pictures directory on Android
      if (Platform.isAndroid) {
        final publicPictures = Directory('/storage/emulated/0/Pictures/MuslimLauncher');
        try {
          if (!await publicPictures.exists()) {
            await publicPictures.create(recursive: true);
          }
          targetDir = publicPictures;
        } catch (_) {
          // Fallback if public pictures fails
        }
      }

      // 2. Fallback to app external storage pictures
      if (targetDir == null) {
        try {
          final extDirs = await getExternalStorageDirectories(
            type: StorageDirectory.pictures,
          );
          if (extDirs != null && extDirs.isNotEmpty) {
            targetDir = extDirs.first;
          }
        } catch (_) {}
      }

      // 3. Last fallback to app documents directory
      targetDir ??= await getApplicationDocumentsDirectory();

      final savedFile = File('${targetDir.path}/$fileName');
      await savedFile.writeAsBytes(bytes, flush: true);
      return savedFile.path;
    } catch (e) {
      debugPrint('MilestoneShareService.saveMilestoneToGallery error: $e');
      return null;
    }
  }

  /// Builds the localized social share text
  static String buildShareText({
    required String title,
    required String subtitle,
    String? ayahOrDzikirCount,
  }) {
    final countText = ayahOrDzikirCount != null && ayahOrDzikirCount.isNotEmpty
        ? ' ($ayahOrDzikirCount)'
        : '';
    return 'Alhamdulillah! Saya telah menyelesaikan $title$countText bersama Muslim Launcher.\n\n'
        'Mari istiqomahkan ibadah harian dan kendalikan waktu gadgetmu bersama Muslim Launcher:\n'
        'https://play.google.com/store/apps/details?id=com.kraftech.muslim_launcher_2';
  }
}
