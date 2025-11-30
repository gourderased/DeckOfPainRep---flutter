import 'dart:io';
import 'dart:async';
import '../config/ad_config.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // 전면광고 상태
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _hasNavigated = false; // 중복 네비게이션 방지

  @override
  void initState() {
    super.initState();

    // 광고 초기화를 스플래시와 병렬로 시작
    MobileAds.instance.initialize().then((_) {
      _loadInterstitialAd();
    });

    // 최대 6초 후 홈으로 전환
    Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (Platform.isAndroid) {
        _showAdAndNavigate();
      } else {
        // iOS는 바로 홈으로 이동
        print('스플래시: iOS - 홈으로 이동');
        _navigateToHome();
      }
    });
  }

  // 전면광고 로딩
  void _loadInterstitialAd() {
    // 안드로이드만 지원
    if (!Platform.isAndroid) {
      print('스플래시: iOS는 스플래시 광고 지원 안함');
      return;
    }
    print('스플래시: 전면광고 로딩 시작 - ${AdConfig.interstitialAdUnitId}');
    
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('스플래시: 전면광고 로딩 성공');
          setState(() {
            _interstitialAd = ad;
            _isAdReady = true;
          });
          
          // 광고 닫힘 콜백 설정
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('스플래시: 전면광고 닫힘 - 홈으로 이동');
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              print('스플래시: 홈으로 이동');
              Navigator.of(context).pushReplacementNamed('/home');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('스플래시: 전면광고 표시 실패: $error - 홈으로 이동');
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              print('스플래시: 홈으로 이동');
              Navigator.of(context).pushReplacementNamed('/home');
            },
          );
          
          // 광고가 로딩되면 즉시 표시 (3초 대기 없이)
          if (!_hasNavigated) {
            print('스플래시: 광고 로딩 완료, 즉시 표시');
            _showAdAndNavigate();
          } else {
            print('스플래시: 이미 이동했음, 광고 표시 건너뜀');
          }
        },
        onAdFailedToLoad: (error) {
          print('스플래시: 전면광고 로딩 실패: $error');
          setState(() {
            _isAdReady = false;
          });
        },
      ),
    );
  }

  // 광고 표시 후 네비게이션
  void _showAdAndNavigate() {
    if (_hasNavigated) {
      print('스플래시: 이미 이동했음, 중복 실행 방지');
      return; // 중복 실행 방지
    }
    
    print('스플래시: 광고 표시 시도 - 준비됨: $_isAdReady, 광고: ${_interstitialAd != null}');
    if (_isAdReady && _interstitialAd != null) {
      print('스플래시: 전면광고 표시');
      _hasNavigated = true; // 광고 표시 전에 플래그 설정
      _interstitialAd!.show();
    } else {
      print('스플래시: 광고 준비 안됨, 홈으로 이동');
      _navigateToHome();
    }
  }

  // 홈 화면으로 이동
  void _navigateToHome() {
    if (!mounted) return;
    if (_hasNavigated) {
      print('스플래시: 이미 이동했음, 중복 실행 방지');
      return;
    }
    _hasNavigated = true;
    print('스플래시: 홈으로 이동');
    Navigator.of(context).pushReplacementNamed('/home');
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


