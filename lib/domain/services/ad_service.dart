import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/platform/platform_service.dart';
import '../../core/constants/app_constants.dart';

/// 광고 관리 서비스
class AdService {
  final PlatformService _platformService;

  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  bool _isInterstitialReady = false;
  bool _isBannerReady = false;

  AdService(this._platformService);

  bool get isInterstitialReady => _isInterstitialReady;
  bool get isBannerReady => _isBannerReady;
  BannerAd? get bannerAd => _bannerAd;

  Future<void> loadInterstitial({
    VoidCallback? onAdLoaded,
    VoidCallback? onAdClosed,
    Function(String)? onAdFailed,
  }) async {
    final adUnitId = _platformService.getInterstitialAdId(
      isTestMode: AppConstants.isAdTestMode,
    );

    if (adUnitId.isEmpty) return;

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _disposeInterstitial();
              onAdClosed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _disposeInterstitial();
              onAdFailed?.call(error.toString());
            },
          );

          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
          onAdFailed?.call(error.toString());
        },
      ),
    );
  }

  void showInterstitialOrExecute(VoidCallback fallback) {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      fallback();
    }
  }

  Future<void> loadBanner({
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailed,
  }) async {
    final adUnitId = _platformService.getBannerAdId(
      isTestMode: AppConstants.isAdTestMode,
    );

    if (adUnitId.isEmpty) return;

    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAd = ad as BannerAd;
          _isBannerReady = true;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _isBannerReady = false;
          onAdFailed?.call(error.toString());
        },
      ),
      request: const AdRequest(),
    );

    await ad.load();
  }

  void _disposeInterstitial() {
    _interstitialAd = null;
    _isInterstitialReady = false;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _disposeInterstitial();
    _bannerAd = null;
    _isBannerReady = false;
  }
}
