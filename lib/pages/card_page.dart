import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/platform/platform_service.dart';
import '../domain/services/ad_service.dart';
import '../domain/services/deck_service.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../data/models/workout_result.dart';
import 'result_page.dart';

/// 카드 운동 화면 (Riverpod 버전)
class CardPage extends ConsumerStatefulWidget {
  const CardPage({super.key});

  @override
  ConsumerState<CardPage> createState() => _CardPageState();
}

class _CardPageState extends ConsumerState<CardPage> {
  late final AdService _adService;
  late final DeckService _deckService;
  BannerAd? _bannerAd;
  bool _isBannerReady = false;
  bool _adAlreadyShown = false;

  @override
  void initState() {
    super.initState();

    final platformService = PlatformServiceFactory.instance;
    _adService = AdService(platformService);
    _deckService = DeckService();

    // 운동 세션 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      ref.read(workoutSessionProvider.notifier).initializeSession(settings);
    });

    // 광고 로드
    _adService.loadInterstitial(onAdClosed: _navigateToResult);
    _loadBanner();
  }

  void _loadBanner() {
    _adService.loadBanner(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _bannerAd = _adService.bannerAd;
            _isBannerReady = _adService.isBannerReady;
          });
        }
      },
    );
  }

  void _showAdThenResult() {
    if (_adAlreadyShown) {
      _navigateToResult();
      return;
    }

    _adAlreadyShown = true;
    _adService.showInterstitialOrExecute(_navigateToResult);
  }

  void _navigateToResult() {
    final sessionState = ref.read(workoutSessionProvider);
    final settings = ref.read(settingsProvider);
    final start = sessionState.sessionStartTime ?? DateTime.now();
    final totalSec = DateTime.now().difference(start).inSeconds;

    final exerciseToSuit = {
      settings.diamondExercise: 'diamond',
      settings.heartExercise: 'heart',
      settings.spadeExercise: 'spade',
      settings.clubExercise: 'clover',
    };

    final result = WorkoutResult(
      totalSeconds: totalSec,
      totalCards: sessionState.completedCards,
      countsByExercise: sessionState.exerciseCounts,
      exerciseToSuit: exerciseToSuit,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultPage(result: result)),
    );
  }

  /// 운동 종료 확인 다이얼로그 표시
  Future<bool?> _showExitConfirmDialog() async {
    final sessionState = ref.read(workoutSessionProvider);

    // 운동이 시작되지 않았거나 이미 완료된 경우 다이얼로그 없이 바로 뒤로가기
    if (sessionState.state == WorkoutState.notStarted ||
        sessionState.state == WorkoutState.completed) {
      return true;
    }

    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('운동 종료'),
          content: const Text('운동을 종료하시겠습니까?\n진행 상황이 저장되지 않습니다.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('종료'),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('운동 종료'),
          content: const Text('운동을 종료하시겠습니까?\n진행 상황이 저장되지 않습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('종료', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(workoutSessionProvider);
    final sessionNotifier = ref.read(workoutSessionProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    // 운동 완료 감지
    if (sessionState.state == WorkoutState.completed && !_adAlreadyShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAdThenResult();
      });
    }

    final isStart = sessionState.state == WorkoutState.notStarted;
    final progressText =
        '${sessionState.completedCards.clamp(0, sessionState.targetCards)}/${sessionState.targetCards}';
    final progressValue = sessionState.progress;

    // 버튼 상태
    String buttonLabel;
    VoidCallback? onPressed;
    final Color bg = sessionState.state == WorkoutState.resting ? Colors.white10 : cs.primary;
    final Color fg = sessionState.state == WorkoutState.resting ? Colors.white70 : Colors.black;

    if (isStart) {
      buttonLabel = '시작';
      onPressed = () => sessionNotifier.start();
    } else if (sessionState.state == WorkoutState.resting) {
      buttonLabel = '휴식 중...';
      onPressed = null;
    } else if (sessionState.state == WorkoutState.readyForNext) {
      buttonLabel = '다음 카드';
      onPressed = () => sessionNotifier.nextCard();
    } else {
      buttonLabel = '수행 완료';
      onPressed = () => sessionNotifier.completeCurrentCard();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _showExitConfirmDialog();
        if (shouldPop == true && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0C0C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0C0C),
          foregroundColor: Colors.white,
          title: const Text('Deck'),
          centerTitle: true,
        ),
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 컨텐츠 (진행도, 카드 이미지, 운동 지시)
            Column(
              children: [
                // 진행도 바
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: Colors.white10,
                          color: cs.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(progressText, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),

                // 중앙 카드 이미지
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Image.asset(
                        isStart
                            ? 'assets/card_questionmark.png'
                            : sessionNotifier.getCurrentAssetPath() ?? 'assets/card_questionmark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // 운동 지시 + 휴식 표시
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    children: [
                      if (!isStart && sessionNotifier.getCurrentInstruction() != null)
                        Text(
                          sessionNotifier.getCurrentInstruction()!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 6),
                      if (sessionState.state == WorkoutState.resting)
                        Text(
                          '휴식 ${sessionState.restSecondsLeft}초',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),

                // 하단 여백 (버튼 + 광고 영역 확보)
                const SizedBox(height: 126), // 48(버튼) + 16(패딩) + 50(광고) + 12(여백)
              ],
            ),

            // 하단 CTA 버튼 (고정 위치)
            Positioned(
              left: 16,
              right: 16,
              bottom: 62, // 배너 높이(50) + 하단 여백(12)
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: fg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  child: Text(buttonLabel),
                ),
              ),
            ),

            // 배너 광고 영역 (고정 위치)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 50,
                  child: _isBannerReady && _bannerAd != null
                      ? AdWidget(ad: _bannerAd!)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
