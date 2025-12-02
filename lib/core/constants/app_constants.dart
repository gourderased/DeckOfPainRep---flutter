/// 앱 전역 상수 관리
class AppConstants {
  AppConstants._();

  // 광고 테스트 모드
  static const bool isAdTestMode = true;

  // 테스트 광고 ID
  static const String testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialIOS =
      'ca-app-pub-3940256099942544/4411468910';
  static const String testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';

  // 프로덕션 광고 ID
  static const String prodInterstitialAndroid =
      'ca-app-pub-8765826216210017/7902839778';
  static const String prodInterstitialIOS =
      'ca-app-pub-8765826216210017/5101879635';
  static const String prodBannerAndroid =
      'ca-app-pub-8765826216210017/4786081065';
  static const String prodBannerIOS = 'ca-app-pub-8765826216210017/5495813062';

  // 덱 설정
  static const int totalCardsInDeck = 54;
  static const int minTotalSets = 1;
  static const int maxTotalSets = 54;

  // 스플래시 설정
  static const int splashDurationSeconds = 6;
}
