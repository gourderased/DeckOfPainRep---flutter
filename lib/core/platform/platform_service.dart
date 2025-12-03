import 'dart:io';
import '../constants/app_constants.dart';

/// 플랫폼별 동작을 추상화하는 인터페이스
abstract class PlatformService {
  bool get shouldShowSplashAd;
  bool get needsATTPermission;
  String getInterstitialAdId({required bool isTestMode});
  String getBannerAdId({required bool isTestMode});
  String get platformName;
}

/// Android 플랫폼 서비스
class AndroidPlatformService implements PlatformService {
  @override
  bool get shouldShowSplashAd => true;

  @override
  bool get needsATTPermission => false;

  @override
  String getInterstitialAdId({required bool isTestMode}) {
    return isTestMode
        ? AppConstants.testInterstitialAndroid
        : AppConstants.prodInterstitialAndroid;
  }

  @override
  String getBannerAdId({required bool isTestMode}) {
    return isTestMode
        ? AppConstants.testBannerAndroid
        : AppConstants.prodBannerAndroid;
  }

  @override
  String get platformName => 'Android';
}

/// iOS 플랫폼 서비스
class IOSPlatformService implements PlatformService {
  @override
  bool get shouldShowSplashAd => false;

  @override
  bool get needsATTPermission => true;

  @override
  String getInterstitialAdId({required bool isTestMode}) {
    return isTestMode
        ? AppConstants.testInterstitialIOS
        : AppConstants.prodInterstitialIOS;
  }

  @override
  String getBannerAdId({required bool isTestMode}) {
    return isTestMode
        ? AppConstants.testBannerIOS
        : AppConstants.prodBannerIOS;
  }

  @override
  String get platformName => 'iOS';
}

/// PlatformService 팩토리
class PlatformServiceFactory {
  PlatformServiceFactory._();

  static PlatformService? _instance;

  static PlatformService get instance {
    _instance ??= _createPlatformService();
    return _instance!;
  }

  static PlatformService _createPlatformService() {
    if (Platform.isAndroid) {
      return AndroidPlatformService();
    } else if (Platform.isIOS) {
      return IOSPlatformService();
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }
}
