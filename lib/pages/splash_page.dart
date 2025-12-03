import 'dart:async';
import 'package:flutter/material.dart';
import '../core/platform/platform_service.dart';
import '../core/constants/app_constants.dart';
import '../domain/services/ad_service.dart';

/// 스플래시 화면
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final PlatformService _platformService;
  late final AdService _adService;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _platformService = PlatformServiceFactory.instance;
    _adService = AdService(_platformService);

    // 플랫폼별 스플래시 광고 로드
    if (_platformService.shouldShowSplashAd) {
      _adService.loadInterstitial(
        onAdClosed: _navigateToHome,
        onAdFailed: (error) {
          debugPrint('[SplashPage] 광고 로드 실패: $error');
          _navigateToHome();
        },
      );
    }

    // 스플래시 타이머 (6초)
    Timer(const Duration(seconds: AppConstants.splashDurationSeconds), () {
      if (!mounted) return;

      if (_platformService.shouldShowSplashAd) {
        _showAdAndNavigate();
      } else {
        _navigateToHome();
      }
    });
  }

  void _showAdAndNavigate() {
    if (_hasNavigated) return;

    // 광고가 준비되지 않았으면 바로 홈으로 이동
    if (!_adService.isInterstitialReady) {
      _navigateToHome();
      return;
    }

    // 광고 표시 (광고가 닫히면 onAdClosed 콜백으로 _navigateToHome 호출됨)
    _adService.showInterstitialOrExecute(_navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image(
          image: AssetImage('assets/main_logo.png'),
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
