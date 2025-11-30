import 'result_page.dart';                 // ▶ 결과 화면
import 'package:flutter/material.dart';    // ▶ 기본 위젯
import 'dart:async';                       // ▶ 휴식 타이머
import '../config/ad_config.dart';         // ▶ 광고 ID 설정
import 'dart:math';                        // ▶ 카드 셔플용 난수
import 'package:shared_preferences/shared_preferences.dart'; // ▶ 설정값 로드
import 'package:google_mobile_ads/google_mobile_ads.dart';   // ▶ AdMob 전면/배너 광고
// SVG → PNG 변경으로 flutter_svg 제거

// ─────────────────────────────────────────────────────────────────────────────
// CardPage
// - 카드 덱 진행
// - 마지막 카드(세트 수 충족)에서 전면광고(Interstitial) 노출 후 결과 화면 이동
// - 화면 하단 버튼 아래에 배너 광고(Banner) 고정 노출
// ─────────────────────────────────────────────────────────────────────────────

class CardPage extends StatefulWidget {
  const CardPage({super.key});
  @override
  State<CardPage> createState() => _CardPageState();
}

// 카드 무늬(자산명이 clover라서 enum도 clover 사용)
enum Suit { spade, diamond, heart, clover }

// 한 장의 카드 모델: suit가 null이면 Joker(빨강/검정은 rank로 구분)
class PlayingCard {
  final Suit? suit;     // null이면 Joker
  final String rank;    // 2-10, J,Q,K,A, 또는 'JokerR' / 'JokerB'
  const PlayingCard(this.suit, this.rank);
}

class _CardPageState extends State<CardPage> {
  // ────────────────────────────── 덱/인덱스/목표세트 ──────────────────────────────
  late List<PlayingCard> _deck; // 전체 덱 54장(+조커2)
  int _index = -1;              // -1이면 시작 전(물음표 카드 상태)
  int _targetCards = 20;        // 설정에서 불러오는 "총 세트 수(=카드 장수)"

  // ─────────────────────────────── 설정(SharedPreferences) ─────────────────────
  int aCount = 30, jCount = 15, qCount = 20, kCount = 25, jokerCount = 40; // J/Q/K/A/조커 횟수
  int restSec = 30;                                                         // 휴식(초)
  String nameSpade = '푸시업', nameDiamond = '스쿼트', nameHeart = '버피', nameClub = '런지'; // 무늬별 운동명

  // ────────────────────────────── 진행 상태(휴식 등) ──────────────────────────────
  Timer? _timer;                     // 휴식 타이머
  int _restLeft = 0;                 // 남은 휴식 초
  bool get _isResting => _restLeft > 0;
  bool _readyForNext = false;        // 휴식 끝나고 '다음 카드' 대기 상태

  // Joker 카드 선택 캐시(해당 인덱스에서 어떤 운동으로 할지 고정)
  final Map<int, String> _jokerChoice = {};
  final _rng = Random();

  // 결과 집계: 세션 시간 + 운동별 누적 횟수
  DateTime? _sessionStart;
  final Map<String, int> _countsByExercise = {};

  // ────────────────────────────── AdMob 전면 광고 상태 ───────────────────────────
  InterstitialAd? _interstitialAd;   // 로드된 전면광고 인스턴스
  bool _isAdReady = false;           // 전면광고 로드 완료 여부
  bool _adAlreadyShown = false;      // 한 세션에서 만 표시(원하면 제거 가능)

  // ────────────────────────────── AdMob 배너 광고 상태 ───────────────────────────
  BannerAd? _bannerAd;               // 배너 인스턴스
  bool _isBannerReady = false;       // 배너 로드 완료 여부

  @override
  void initState() {
    super.initState();
    _buildDeck();            // 덱 생성 및 셔플
    _loadSettings();         // SharedPreferences에서 설정 로드
    _loadInterstitial();     // ▶ 전면광고 미리 로드
    
    // 첫 프레임 렌더링 후에 배너 로드 → 초기 렌더 방해 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBanner();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();            // 타이머 정리
    _interstitialAd?.dispose();  // 전면 광고 정리
    _bannerAd?.dispose();        // 배너 광고 정리
    super.dispose();
  }

  // 덱 구성 + 셔플
  void _buildDeck() {
    final deck = <PlayingCard>[];
    const ranks = ['2','3','4','5','6','7','8','9','10','J','Q','K','A'];
    for (final s in Suit.values) {
      for (final r in ranks) {
        deck.add(PlayingCard(s, r));
      }
    }
    // 조커(빨강/검정)
    deck.add(const PlayingCard(null, 'JokerR'));
    deck.add(const PlayingCard(null, 'JokerB'));
    deck.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    _deck = deck;
  }

  // SharedPreferences에서 설정 로드
  Future<void> _loadSettings() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      aCount       = sp.getInt('settings.A')     ?? aCount;
      jCount       = sp.getInt('settings.J')     ?? jCount;
      qCount       = sp.getInt('settings.Q')     ?? qCount;
      kCount       = sp.getInt('settings.K')     ?? kCount;
      jokerCount   = sp.getInt('settings.Joker') ?? jokerCount;
      restSec      = sp.getInt('settings.Rest')  ?? restSec;
      _targetCards = (sp.getInt('settings.TotalSets') ?? _targetCards).clamp(1, 54);

      nameSpade   = sp.getString('settings.Spade')   ?? nameSpade;
      nameDiamond = sp.getString('settings.Diamond') ?? nameDiamond;
      nameHeart   = sp.getString('settings.Heart')   ?? nameHeart;
      nameClub    = sp.getString('settings.Club')    ?? nameClub;
    });
  }

  // ────────────────────────────── 전면 광고(Interstitial) ───────────────────────
  String get _interstitialUnitId => AdConfig.interstitialAdUnitId;

  void _loadInterstitial() {
    if (_interstitialUnitId.isEmpty) return;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;

          // 전체화면 콜백 등록(닫힘/실패 시 결과화면으로 이동)
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              _navigateToResult();
              _loadInterstitial(); // 다음 세션 대비 재로드(선택)
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isAdReady = false;
              _navigateToResult();
              _loadInterstitial(); // 실패해도 다음 대비 재로드(선택)
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isAdReady = false;
        },
      ),
    );
  }

  // “광고 → 결과 화면” 순서로 처리
  void _showAdThenResult() {
    if (_adAlreadyShown) {
      // 같은 세션에서 중복 노출 방지(원하면 제거 가능)
      _navigateToResult();
      return;
    }
    if (_isAdReady && _interstitialAd != null) {
      _adAlreadyShown = true;
      _interstitialAd!.show(); // onAdDismissed에서 결과 화면으로 이동
    } else {
      // 광고가 준비 안 됐으면 곧바로 결과 화면
      _navigateToResult();
    }
  }

  // 실제 결과 화면으로 이동(Navigator)
  void _navigateToResult() {
    final start = _sessionStart ?? DateTime.now();
    final totalSec = DateTime.now().difference(start).inSeconds;
    final totalCards = (_index + 1).clamp(0, _targetCards);

    // 운동명 → 무늬 매핑(결과 화면에서 아이콘 색칠용)
    final Map<String, String> exerciseToSuit = {
      nameDiamond: 'diamond',
      nameHeart: 'heart',
      nameSpade: 'spade',
      nameClub: 'clover',
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          totalSeconds: totalSec,
          countsByExercise: _countsByExercise,
          totalCards: totalCards,
          exerciseToSuit: exerciseToSuit,
        ),
      ),
    );
  }

  // ────────────────────────────── 배너 광고(Banner) ─────────────────────────────
  String get _bannerUnitId => AdConfig.bannerAdUnitId;

  void _loadBanner() {
    if (_bannerUnitId.isEmpty) return;

    final ad = BannerAd(
      size: AdSize.banner, // 간단한 고정 배너(Adaptive가 필요하면 교체)
      adUnitId: _bannerUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _bannerAd = null;
            _isBannerReady = false;
          });
        },
      ),
      request: const AdRequest(),
    );

    ad.load();
  }

  // ────────────────────────────── 운동 로직 ─────────────────────────────
  // 현재 카드의 운동명(조커는 색상에 맞는 풀에서 랜덤 선택, 동일 인덱스에서는 고정)
  String exerciseNameFor(PlayingCard c, int deckIndex) {
    if (c.rank == 'JokerR' || c.rank == 'JokerB') {
      final cached = _jokerChoice[deckIndex];
      if (cached != null) return cached;
      final pool = (c.rank == 'JokerR')
          ? [nameDiamond, nameHeart] // 빨강 조커 → 다이아/하트
          : [nameSpade, nameClub];   // 검정 조커 → 스페이드/클로버
      final chosen = pool[_rng.nextInt(pool.length)];
      _jokerChoice[deckIndex] = chosen;
      return chosen;
    }
    return switch (c.suit!) {
      Suit.spade   => nameSpade,
      Suit.diamond => nameDiamond,
      Suit.heart   => nameHeart,
      Suit.clover  => nameClub,
    };
  }

  // 카드의 반복 횟수(J/Q/K/A/조커는 설정값, 숫자는 그대로)
  int repsFor(PlayingCard c) {
    if (c.rank == 'JokerR' || c.rank == 'JokerB') return jokerCount;
    return switch (c.rank) {
      'J' => jCount,
      'Q' => qCount,
      'K' => kCount,
      'A' => aCount,
      _   => int.tryParse(c.rank) ?? 0,
    };
  }

  // 화면 표시용 지시 문구
  String instructionFor(PlayingCard c, int deckIndex) {
    final name = exerciseNameFor(c, deckIndex);
    final reps = repsFor(c);
    return '$name - $reps회';
  }

  // 자산 파일명(프로젝트의 SVG 네이밍 규칙에 맞춤)
  String assetNameFor(PlayingCard c) {
    if (c.rank == 'JokerR') return 'assets/card_joker2.png'; // 빨강
    if (c.rank == 'JokerB') return 'assets/card_joker1.png'; // 검정
    final suitStr = switch (c.suit!) {
      Suit.spade   => 'spade',
      Suit.diamond => 'diamond',
      Suit.heart   => 'heart',
      Suit.clover  => 'clover',
    };
    final rankStr = switch (c.rank) {
      'A'  => 'ace',
      'K'  => 'king',
      'Q'  => 'queen',
      'J'  => 'junior', // 프로젝트 자산이 jack가 아니라 "junior"로 되어 있음
      '2'  => 'two',
      '3'  => 'three',
      '4'  => 'four',
      '5'  => 'five',
      '6'  => 'six',
      '7'  => 'seven',
      '8'  => 'eight',
      '9'  => 'nine',
      '10' => 'ten',
      _    => c.rank,
    };
    return 'assets/card_${suitStr}_$rankStr.png';
  }

  // ────────────────────────────── 카드 진행 ─────────────────────────────
  void _next() {
    if (_isResting) return;

    // 목표 장수 보호: 목표 초과하지 않도록
    if (_index + 1 >= _targetCards) {
      setState(() => _index = _targetCards - 1);
      return;
    }

    // 덱 끝 보호
    if (_index >= _deck.length - 1) {
      setState(() => _index = _deck.length - 1);
      return;
    }

    setState(() {
      _index++;
      _readyForNext = false; // 새 카드 진입 → '수행 완료' 대기 상태
    });
  }

  // “수행 완료” 클릭 시 처리:
  //  1) 현재 카드 실적 집계
  //  2) 이번 카드로 목표 달성이라면: 광고 → 결과 화면
  //  3) 아니라면: 휴식(설정이 0이면 즉시 '다음 카드' 상태)
  void _onComplete() {
    if (_isResting || _readyForNext || _index < 0) return; // 시작 전/휴식 중이면 무시

    // 현재 카드 실적 집계
    final c = _deck[_index];
    final name = exerciseNameFor(c, _index);
    final reps = repsFor(c);
    _countsByExercise[name] = (_countsByExercise[name] ?? 0) + reps;

    // 이번 카드까지 완료한 장수
    final completedCards = _index + 1;
    final reachedTarget = completedCards >= _targetCards;

    if (reachedTarget) {
      // ★ 목표 달성 시: 곧바로 광고 → 결과
      _showAdThenResult();
      return;
    }

    // 휴식 타이머 시작(0이면 즉시 '다음 카드' 상태로)
    if (restSec <= 0) {
      setState(() {
        _restLeft = 0;
        _readyForNext = true;
      });
      return;
    }
    _startRest();
  }

  // 휴식 타이머
  void _startRest() {
    _timer?.cancel();
    setState(() {
      _restLeft = restSec;
      _readyForNext = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_restLeft > 0) _restLeft--;
        if (_restLeft <= 0) {
          t.cancel();
          _readyForNext = true; // 휴식 끝 → '다음 카드'
        }
      });
    });
  }

  // ────────────────────────────── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isStart = _index == -1;             // 물음표 카드 상태?
    final c = isStart ? null : _deck[_index]; // 현재 카드

    final progressText = isStart
        ? '0/$_targetCards'
        : '${(_index + 1).clamp(0, _targetCards)}/$_targetCards';
    final progressValue = isStart
        ? 0.0
        : ((_index + 1).clamp(0, _targetCards) / _targetCards);

    // 버튼 상태/라벨 결정
    String buttonLabel;
    VoidCallback? onPressed;
    final Color bg = _isResting ? Colors.white10 : cs.primary;
    final Color fg = _isResting ? Colors.white70 : Colors.black;

    if (isStart) {
      // 시작 전: '시작' 버튼
      buttonLabel = '시작';
      onPressed = () {
        setState(() => _index = 0);
        _sessionStart ??= DateTime.now(); // 세션 시작 시각 기록
      };
    } else if (_isResting) {
      // 휴식 중: 비활성
      buttonLabel = '휴식 중...';
      onPressed = null;
    } else if (_readyForNext) {
      // 휴식 끝: 다음 카드로
      buttonLabel = '다음 카드';
      onPressed = _next;
    } else {
      // 카드 수행 중: '수행 완료'
      buttonLabel = '수행 완료';
      onPressed = _onComplete;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0C),   // 전체 배경: 진한 블랙톤
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0C), // 앱바도 동일 톤
        foregroundColor: Colors.white,
        title: const Text('Deck'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 진행도(현재/목표)
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
                  aspectRatio: 3 / 4, // 카드 비율
                  child: Image.asset(
                    isStart ? 'assets/card_questionmark.png' : assetNameFor(c!),
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
                  if (!isStart)
                    Text(
                      instructionFor(c!, _index),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 6),
                  if (_isResting)
                    Text('휴식 $_restLeft초',
                        style: TextStyle(color: cs.primary, fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            // 하단 CTA 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // ← 배너와 간격을 조금 더 좁힘
              child: SizedBox(
                width: double.infinity,
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

            // ───────────────────────────── 하단 배너 영역 (고정) ───────────────────────────
            // 배너 영역을 고정하여 UI 레이아웃 변화 방지
            SafeArea(
              top: false,
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: 50, // 배너 높이 고정 (AdSize.banner는 보통 50px)
                child: _isBannerReady && _bannerAd != null
                    ? AdWidget(ad: _bannerAd!)
                    : const SizedBox.shrink(), // 광고가 없으면 빈 공간
              ),
            ),

            const SizedBox(height: 12), // 하단 여백(소프트키/제스처 영역 대비)
          ],
        ),
      ),
    );
  }
}