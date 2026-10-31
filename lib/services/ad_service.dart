import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  // ── Official Google AdMob Test Ad Unit IDs ─────────────────────────────────
  // Ganti ID ini dengan Ad Unit ID produksi saat rilis aplikasi.
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android Test Rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded
    }
    return '';
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner
    }
    return '';
  }

  /// Inisialisasi Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        // Langsung preload 1 iklan reward di background agar saat dibutuhkan sudah siap
        preloadRewardedAd();
      }
    } catch (e) {
      debugPrint('[AdService] MobileAds init error: $e');
    }
  }

  /// Preload Rewarded Ad agar tidak perlu menunggu saat ditekan
  void preloadRewardedAd() {
    if (!_isInitialized || _isLoadingRewarded || _rewardedAd != null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded ad failed to load: ${error.message} (code: ${error.code})');
          _rewardedAd = null;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  /// Menampilkan Rewarded Ad jika ada.
  /// Return `true` jika iklan berhasil ditayangkan dan pengguna menyelesaikan tontonan (reward earned).
  /// Return `false` jika iklan tidak tersedia / gagal tayang / offline (sehingga caller bisa langsung bypass).
  Future<bool> showRewardedAd({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    // Jika belum ada iklan yang siap, coba tunggu sebentar atau load cepat
    if (_rewardedAd == null) {
      preloadRewardedAd();
      final completer = Completer<bool>();
      Timer? timer;
      
      // Tunggu hingga ad loaded atau timeout
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          debugPrint('[AdService] Rewarded ad wait timeout -> bypass ke unlock biasa.');
          completer.complete(false);
        }
      });

      // Poll setiap 300ms untuk cek apakah sudah terload
      final pollTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        if (_rewardedAd != null) {
          t.cancel();
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(true);
        } else if (!_isLoadingRewarded) {
          // Gagal load (offline/no fill)
          t.cancel();
          timer?.cancel();
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      final isReady = await completer.future;
      pollTimer.cancel();
      timer.cancel();

      if (!isReady || _rewardedAd == null) {
        return false;
      }
    }

    final ad = _rewardedAd!;
    _rewardedAd = null; // Consume ad

    final adCompleter = Completer<bool>();
    bool earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded ad showed full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded ad dismissed.');
        ad.dispose();
        preloadRewardedAd(); // Siapkan untuk sesi berikutnya
        if (!adCompleter.isCompleted) {
          adCompleter.complete(earnedReward);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        preloadRewardedAd();
        if (!adCompleter.isCompleted) {
          adCompleter.complete(false);
        }
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (adWithoutView, reward) {
          debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
          earnedReward = true;
        },
      );
    } catch (e) {
      debugPrint('[AdService] Error showing rewarded ad: $e');
      preloadRewardedAd();
      return false;
    }

    return await adCompleter.future;
  }
}
