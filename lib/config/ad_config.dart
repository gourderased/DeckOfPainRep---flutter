import 'dart:io';

class AdConfig {
  // 테스트 모드 여부 (true: 테스트 ID 사용, false: 실제 ID 사용)
  static const bool isTestMode = false;
  
  // 테스트 광고 ID (Google AdMob 테스트 ID)
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOS = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/6300978111';
  
  // 실제 광고 ID (배포용)
  static const String _prodInterstitialAndroid = 'ca-app-pub-8765826216210017/7902839778';
  static const String _prodInterstitialIOS = 'ca-app-pub-8765826216210017/5101879635';
  static const String _prodBannerAndroid = 'ca-app-pub-8765826216210017/4786081065';
  static const String _prodBannerIOS = 'ca-app-pub-8765826216210017/5495813062';
  
  // 전면광고 ID 가져오기
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? _testInterstitialAndroid : _prodInterstitialAndroid;
    } else if (Platform.isIOS) {
      return isTestMode ? _testInterstitialIOS : _prodInterstitialIOS;
    }
    return '';
  }
  
  // 배너광고 ID 가져오기
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? _testBannerAndroid : _prodBannerAndroid;
    } else if (Platform.isIOS) {
      return isTestMode ? _testBannerIOS : _prodBannerIOS;
    }
    return '';
  }
  
  // 테스트 모드 토글 (개발 중에만 사용)
  static void toggleTestMode() {
    // 이 메서드는 개발 중에만 사용하고, 실제 배포 시에는 제거하거나 주석 처리
    // isTestMode = !isTestMode;
  }
}
