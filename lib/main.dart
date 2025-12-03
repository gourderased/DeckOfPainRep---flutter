import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

// Core
import 'core/platform/platform_service.dart';

// Pages
import 'pages/splash_page.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/card_page.dart';
import 'pages/how_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 플랫폼 서비스 초기화
  final platformService = PlatformServiceFactory.instance;

  // iOS에서 App Tracking Transparency 권한 요청
  if (platformService.needsATTPermission) {
    await _requestTrackingPermission();
  }

  // 광고 SDK 초기화 (ATT 권한 요청 후)
  await MobileAds.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

/// iOS에서 App Tracking Transparency 권한을 요청하는 함수
Future<void> _requestTrackingPermission() async {
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;

    if (status == TrackingStatus.notDetermined) {
      final result =
          await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('[ATT] 권한 결과: $result');
    } else {
      debugPrint('[ATT] 현재 권한 상태: $status');
    }
  } catch (e) {
    debugPrint('[ATT] 권한 요청 중 오류 발생: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deck of Pain',
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
      ),
      routes: {
        '/': (_) => const SplashPage(),
        '/home': (_) => const HomePage(),
        '/settings': (_) => const SettingsPage(),
        '/card': (_) => const CardPage(),
        '/how': (_) => const HowPage(),
      },
    );
  }
}
