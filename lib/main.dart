import 'dart:io'; 
import 'pages/how_page.dart';
import 'pages/home_page.dart';
import 'pages/card_page.dart';
import 'pages/splash_page.dart';
import 'pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 성능 최적화 설정
  // debugPaintSizeEnabled = false; // 레이아웃 디버그 비활성화
  
  // iOS에서 App Tracking Transparency 권한 요청
  if (Platform.isIOS) {
    await _requestTrackingPermission();
  }
  
  // 광고 SDK 초기화는 ATT 권한 요청 후에 진행
  await MobileAds.instance.initialize();
  
  runApp(const MyApp());
}

/// iOS에서 App Tracking Transparency 권한을 요청하는 함수
Future<void> _requestTrackingPermission() async {
  try {
    // 현재 추적 권한 상태 확인
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    
    // 권한이 아직 결정되지 않은 경우에만 요청
    if (status == TrackingStatus.notDetermined) {
      // ATT 권한 요청
      final result = await AppTrackingTransparency.requestTrackingAuthorization();
      
      // 권한 결과에 따른 로깅 (선택사항)
      switch (result) {
        case TrackingStatus.authorized:
          print('ATT 권한 허용됨');
          break;
        case TrackingStatus.denied:
          print('ATT 권한 거부됨');
          break;
        case TrackingStatus.restricted:
          print('ATT 권한 제한됨');
          break;
        case TrackingStatus.notDetermined:
          print('ATT 권한 미결정');
          break;
        case TrackingStatus.notSupported:
          print('ATT 권한 미지원 (iOS 14 미만)');
          break;
      }
    } else {
      print('ATT 권한 상태: $status');
    }
  } catch (e) {
    print('ATT 권한 요청 중 오류 발생: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      title: 'Deck of Pain',
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
        ),

        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF4F46E5),
          brightness: Brightness.dark
        ),
      ),
      routes: {
        '/': (_) => const SplashPage(),
        '/home': (_) => const HomePage(), // 기본 홈 화면
        '/settings': (_) => const SettingsPage(), // 설정 화면
        '/card': (_) => const CardPage(), // 카드 화면
        '/how': (_) => const HowPage(), // 운동 방법 화면
      },
    );
  }
}