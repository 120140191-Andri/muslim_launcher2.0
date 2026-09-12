import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MilestoneShareService {
  static const MethodChannel _channel = MethodChannel('com.muslimlauncher/apps');

  /// Menangkap [boundaryKey] RepaintBoundary menjadi byte PNG resolusi tinggi.
  /// Menangani siklus frame Flutter secara aman agar tidak terjadi error debugNeedsPaint.
  static Future<Uint8List?> capturePng(GlobalKey boundaryKey) async {
    try {
      // Tunggu hingga frame aktif selesai dipaint
      if (WidgetsBinding.instance.hasScheduledFrame) {
        await WidgetsBinding.instance.endOfFrame;
      }

      var boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      int retries = 0;
      while ((boundary == null || boundary.debugNeedsPaint) && retries < 6) {
        await Future.delayed(const Duration(milliseconds: 60));
        boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        retries++;
      }

      if (boundary == null) {
        debugPrint('[MilestoneShareService] RenderRepaintBoundary null setelah menunggu render');
        return null;
      }

      // Render gambar tajam 3.0x pixel ratio (1080x1920)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, stackTrace) {
      debugPrint('[MilestoneShareService] capturePng error: $e\n$stackTrace');
      return null;
    }
  }

  /// Membagikan gambar sertifikat via Lembar Bagikan Sistem (WhatsApp, Instagram Stories, dll.)
  /// 100% Bebas Izin Penyimpanan (Zero Storage Permission).
  static Future<bool> captureAndShare({
    required GlobalKey boundaryKey,
    required String badgeId,
    required String shareText,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final pngBytes = await capturePng(boundaryKey);
      if (pngBytes == null || pngBytes.isEmpty) {
        debugPrint('[MilestoneShareService] Gagal capture gambar PNG untuk share');
        return false;
      }

      final sanitizedBadgeId = badgeId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final fileName = 'sertifikat_${sanitizedBadgeId}_${DateTime.now().millisecondsSinceEpoch}.png';

      // 1. Coba panggil Android Native Chooser langsung via MethodChannel
      if (Platform.isAndroid) {
        try {
          final nativeResult = await _channel.invokeMethod<bool>('shareImage', {
            'bytes': pngBytes,
            'fileName': fileName,
            'title': 'Bagikan Sertifikat Pencapaian',
            'text': shareText,
          });
          if (nativeResult == true) {
            return true;
          }
        } catch (e) {
          debugPrint('[MilestoneShareService] Native share gagal, fallback ke share_plus: $e');
        }
      }

      // 2. Fallback via share_plus
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);

      final xFile = XFile(file.path, mimeType: 'image/png');
      await Share.shareXFiles(
        [xFile],
        text: shareText,
        sharePositionOrigin: sharePositionOrigin,
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('[MilestoneShareService] Share error: $e\n$stackTrace');
      return false;
    }
  }

  /// Menyimpan gambar sertifikat langsung ke Galeri (Folder Pictures/Muslim Launcher)
  /// 100% Bebas Izin Penyimpanan (Zero Storage Permission via Android MediaStore).
  static Future<bool> saveToGallery({
    required GlobalKey boundaryKey,
    required String badgeId,
  }) async {
    try {
      final pngBytes = await capturePng(boundaryKey);
      if (pngBytes == null || pngBytes.isEmpty) {
        debugPrint('[MilestoneShareService] Gagal capture gambar PNG untuk simpan galeri');
        return false;
      }

      final sanitizedBadgeId = badgeId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final fileName = 'Sertifikat_${sanitizedBadgeId}_${DateTime.now().millisecondsSinceEpoch}.png';

      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('saveImageToGallery', {
          'bytes': pngBytes,
          'fileName': fileName,
        });
        return res ?? false;
      }

      // Non-Android fallback (simpan di app documents)
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);
      return true;
    } catch (e, stackTrace) {
      debugPrint('[MilestoneShareService] saveToGallery error: $e\n$stackTrace');
      return false;
    }
  }
}
