import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

/// 설정 화면
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // 횟수 컨트롤러
  final _aCtrl     = TextEditingController();
  final _jCtrl     = TextEditingController();
  final _qCtrl     = TextEditingController();
  final _kCtrl     = TextEditingController();
  final _jokerCtrl = TextEditingController();

  // 문양 매핑 컨트롤러
  final _spadeCtrl   = TextEditingController();
  final _diamondCtrl = TextEditingController();
  final _heartCtrl   = TextEditingController();
  final _clubCtrl    = TextEditingController();

  // 문양 입력 에러 상태(빈칸 검증용)
  bool _errDiamond = false;
  bool _errHeart   = false;
  bool _errSpade   = false;
  bool _errClub    = false;

  // 스낵바(토스트) 스로틀
  DateTime? _lastToastAt;

  // 초기 로드 플래그
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 입력 시 에러 해제
    _diamondCtrl.addListener(() => _clearErrorIfFilled('diamond'));
    _heartCtrl.addListener(() => _clearErrorIfFilled('heart'));
    _spadeCtrl.addListener(() => _clearErrorIfFilled('spade'));
    _clubCtrl.addListener(() => _clearErrorIfFilled('club'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Riverpod 상태를 TextEditingController에 동기화 (초기 1회만)
    if (!_isInitialized) {
      final settings = ref.read(settingsProvider);
      _syncControllersFromSettings(settings);
      _isInitialized = true;
    }
  }

  /// Riverpod 설정을 TextEditingController에 동기화
  void _syncControllersFromSettings(settings) {
    _aCtrl.text = '${settings.aCount}';
    _jCtrl.text = '${settings.jCount}';
    _qCtrl.text = '${settings.qCount}';
    _kCtrl.text = '${settings.kCount}';
    _jokerCtrl.text = '${settings.jokerCount}';

    _spadeCtrl.text = settings.spadeExercise;
    _diamondCtrl.text = settings.diamondExercise;
    _heartCtrl.text = settings.heartExercise;
    _clubCtrl.text = settings.clubExercise;
  }

  @override
  void dispose() {
    _aCtrl.dispose();
    _jCtrl.dispose();
    _qCtrl.dispose();
    _kCtrl.dispose();
    _jokerCtrl.dispose();
    _spadeCtrl.dispose();
    _diamondCtrl.dispose();
    _heartCtrl.dispose();
    _clubCtrl.dispose();
    super.dispose();
  }

  int _parseOr(String s, int fb) {
    final v = int.tryParse(s);
    return (v == null || v < 0) ? fb : v;
  }

  // 문양 입력이 채워지면 에러 해제
  void _clearErrorIfFilled(String which) {
    setState(() {
      if (which == 'diamond' && _diamondCtrl.text.trim().isNotEmpty) _errDiamond = false;
      if (which == 'heart'   && _heartCtrl.text.trim().isNotEmpty)   _errHeart   = false;
      if (which == 'spade'   && _spadeCtrl.text.trim().isNotEmpty)   _errSpade   = false;
      if (which == 'club'    && _clubCtrl.text.trim().isNotEmpty)    _errClub    = false;
    });
  }

  // 문양 입력 검증: 비어 있으면 true 반환 (저장/뒤로 금지)
  bool _validateSuits() {
    final d = _diamondCtrl.text.trim().isEmpty;
    final h = _heartCtrl.text.trim().isEmpty;
    final s = _spadeCtrl.text.trim().isEmpty;
    final c = _clubCtrl.text.trim().isEmpty;

    setState(() {
      _errDiamond = d;
      _errHeart   = h;
      _errSpade   = s;
      _errClub    = c;
    });

    if (d || h || s || c) {
      _showToast('문양별 운동 종목을 모두 입력해 주세요.');
      return false;
    }
    return true;
  }

  void _showToast(String message) {
    final now = DateTime.now();
    if (_lastToastAt != null &&
        now.difference(_lastToastAt!) < const Duration(milliseconds: 900)) {
      return; // 스로틀: 0.9초
    }
    _lastToastAt = now;

    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: cs.onSurface)),
        backgroundColor: const Color.fromARGB(230, 81, 77, 77).withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 문양 텍스트 onChanged (8글자 제한 안내 + 커스텀 전환)
  void _onSuitChanged(String value) {
    if (value.length == 8) {
      _showToast('최대 8글자까지 입력할 수 있어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final preset = ref.watch(presetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
        children: [
          // 프리셋
          _SectionTitle('프리셋'),
          Card(
            color: cs.surface.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: SegmentedButton<SettingsPreset>(
                segments: const [
                  ButtonSegment(value: SettingsPreset.beginner, label: Text('초보', style:TextStyle(fontSize: 14)),   icon: Icon(Icons.flag)),
                  ButtonSegment(value: SettingsPreset.normal,   label: Text('기본', style:TextStyle(fontSize: 14)),   icon: Icon(Icons.star_half)),
                  ButtonSegment(value: SettingsPreset.hard,     label: Text('하드', style:TextStyle(fontSize: 14)),   icon: Icon(Icons.whatshot)),
                  ButtonSegment(value: SettingsPreset.custom,   label: Text('커스텀', style:TextStyle(fontSize: 14)), icon: Icon(Icons.tune)),
                ],
                selected: {preset},
                onSelectionChanged: (s) {
                  ref.read(settingsProvider.notifier).changePreset(s.first);
                  // Riverpod 상태 변경 시 TextEditingController 동기화
                  Future.microtask(() {
                    final newSettings = ref.read(settingsProvider);
                    _syncControllersFromSettings(newSettings);
                  });
                },
                showSelectedIcon: false,
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 휴식 시간
          _SectionTitle('휴식 시간'),
          Card(
            color: cs.surface.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${settings.restSeconds} 초', style: Theme.of(context).textTheme.bodyLarge),
                  Slider(
                    value: settings.restSeconds.toDouble(),
                    min: 0,
                    max: 90,
                    divisions: 18,
                    label: '${settings.restSeconds}초',
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(restSeconds: v.round())
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 총 세트 수(= 카드 장수)
          _SectionTitle('총 세트 수'),
          Card(
            color: cs.surface.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  const Text("세트", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: settings.totalSets.toDouble(),
                      min: 1,
                      max: 54,
                      divisions: 53,
                      label: "${settings.totalSets} 장",
                      onChanged: (v) {
                        ref.read(settingsProvider.notifier).updateSettings(
                          settings.copyWith(totalSets: v.round())
                        );
                      },
                    ),
                  ),
                  Text("${settings.totalSets} 장", style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 그림/조커/에이스 횟수
          _SectionTitle('그림/조커/에이스 카드 횟수'),
          Card(
            color: cs.surface.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _NumberRow(
                    label: 'A',
                    controller: _aCtrl,
                    onChanged: (_) {}, // TextEditingController만 업데이트, 저장은 적용 버튼에서
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'J',
                    controller: _jCtrl,
                    onChanged: (_) {},
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'Q',
                    controller: _qCtrl,
                    onChanged: (_) {},
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'K',
                    controller: _kCtrl,
                    onChanged: (_) {},
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'Joker',
                    controller: _jokerCtrl,
                    onChanged: (_) {},
                    toast: _showToast,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 문양별 운동 종목 (빨강 위 / 검정 아래)
          _SectionTitle('문양별 운동 종목'),
          Card(
            color: cs.surface.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                children: [
                  _SuitTextRow(
                    label: '♦', labelColor: const Color(0xFFE53935),
                    title: '다이아', which: _SuitWhich.diamond,
                    onChanged: _onSuitChanged,
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _SuitTextRow(
                    label: '♥', labelColor: const Color(0xFFE53935),
                    title: '하트', which: _SuitWhich.heart,
                    onChanged: _onSuitChanged,
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _SuitTextRow(
                    label: '♠', labelColor: const Color(0xFFBDBDBD),
                    title: '스페이드', which: _SuitWhich.spade,
                    onChanged: _onSuitChanged,
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _SuitTextRow(
                    label: '♣', labelColor: const Color(0xFFBDBDBD),
                    title: '클로버', which: _SuitWhich.club,
                    onChanged: _onSuitChanged,
                    toast: _showToast,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const SizedBox(height: 72), // 하단 버튼 공간
        ],
      ),

      // 하단 고정 '적용' 버튼
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                if (!_validateSuits()) return;

                // TextEditingController 값을 Riverpod 상태에 최종 동기화
                final current = ref.read(settingsProvider);
                ref.read(settingsProvider.notifier).updateSettings(
                  current.copyWith(
                    aCount: _parseOr(_aCtrl.text, 0),
                    jCount: _parseOr(_jCtrl.text, 0),
                    qCount: _parseOr(_qCtrl.text, 0),
                    kCount: _parseOr(_kCtrl.text, 0),
                    jokerCount: _parseOr(_jokerCtrl.text, 0),
                    spadeExercise: _spadeCtrl.text.trim(),
                    diamondExercise: _diamondCtrl.text.trim(),
                    heartExercise: _heartCtrl.text.trim(),
                    clubExercise: _clubCtrl.text.trim(),
                  )
                );
                // SettingsNotifier가 자동 저장
                _showToast('저장되었습니다');
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('적용'),
            ),
          ),
        ),
      ),
    );
  }
}

// 공용 섹션 타이틀
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

// 숫자 입력 + 증감 버튼 (0~999 제한 + 초과 시 토스트)
class _NumberRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final void Function(String) toast;

  const _NumberRow({
    required this.label,
    required this.controller,
    required this.toast,
    this.onChanged,
  });

  void _capToMax(BuildContext context) {
    final v = int.tryParse(controller.text) ?? 0;
    if (v > 999) {
      controller.text = '999';
      controller.selection = const TextSelection.collapsed(offset: 3);
      toast('최대 999까지 입력할 수 있어요.');
      onChanged?.call(controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3), // 3자리까지
            ],
            onChanged: (s) {
              _capToMax(context);
              onChanged?.call(controller.text);
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: cs.surface.withOpacity(0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixText: '회',
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StepperButton(
          icon: Icons.remove,
          onTap: () {
            final v = int.tryParse(controller.text) ?? 0;
            final nv = (v > 0) ? (v - 1) : 0;
            controller.text = '$nv';
            onChanged?.call(controller.text);
          },
        ),
        const SizedBox(width: 6),
        _StepperButton(
          icon: Icons.add,
          onTap: () {
            final v = int.tryParse(controller.text) ?? 0;
            if (v >= 999) {
              toast('최대 999까지 입력할 수 있어요.');
              controller.text = '999';
            } else {
              controller.text = '${v + 1}';
            }
            onChanged?.call(controller.text);
          },
        ),
      ],
    );
  }
}

// 스텝 버튼
class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Ink(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

// 문양 행 (아이콘 색+라벨 고정, 입력 박스는 외부 컨트롤러 공유)
enum _SuitWhich { spade, diamond, heart, club }

class _SuitTextRow extends StatelessWidget {
  final String label;              // '♦' 같은 아이콘 문자
  final Color labelColor;
  final String title;              // '다이아' 텍스트
  final _SuitWhich which;          // 어떤 문양인지
  final ValueChanged<String> onChanged; // 길이 8 안내
  final void Function(String) toast;

  const _SuitTextRow({
    required this.label,
    required this.labelColor,
    required this.title,
    required this.which,
    required this.onChanged,
    required this.toast,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SettingsPageState>()!;
    final cs = Theme.of(context).colorScheme;
    final errorColor = Colors.redAccent;

    // 현재 컨트롤러/에러상태 참조
    TextEditingController controller;
    bool isError;
    switch (which) {
      case _SuitWhich.diamond:
        controller = state._diamondCtrl; isError = state._errDiamond; break;
      case _SuitWhich.heart:
        controller = state._heartCtrl;   isError = state._errHeart;   break;
      case _SuitWhich.spade:
        controller = state._spadeCtrl;   isError = state._errSpade;   break;
      case _SuitWhich.club:
        controller = state._clubCtrl;    isError = state._errClub;    break;
    }

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(8), // 최대 8글자
            ],
            onChanged: (v) {
              if (v.length == 8) {
                toast('최대 8글자까지 입력할 수 있어요.');
              }
              onChanged(v);
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: cs.surface.withOpacity(0.15),
              hintText: '예: 푸시업 / 스쿼트',
              // 항상 테두리 보이게
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isError ? errorColor : cs.outline.withOpacity(0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isError ? errorColor : cs.outline.withOpacity(0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isError ? errorColor : cs.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
