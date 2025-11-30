import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum Preset { beginner, normal, hard, custom }

class _SettingsPageState extends State<SettingsPage> {
  // ───── 프리셋 기본값 (횟수/휴식/세트수[=카드 장수]) ─────
  static const _defaults = {
    Preset.beginner: {'A': 20, 'J': 10, 'Q': 12, 'K': 15, 'Joker': 30, 'Rest': 30, 'TotalSets': 20},
    Preset.normal:   {'A': 30, 'J': 15, 'Q': 20, 'K': 25, 'Joker': 40, 'Rest': 45, 'TotalSets': 36},
    Preset.hard:     {'A': 40, 'J': 20, 'Q': 25, 'K': 30, 'Joker': 50, 'Rest': 30, 'TotalSets': 54},
  };

  // 상태
  Preset _preset = Preset.beginner; // 기본: 초보
  double _restSec = 30;
  int _totalSets = 20; // 카드 장수(1~54)

  // 변경 여부(추후 UI 마커 등에 사용할 수 있어 유지)
  bool _dirty = false;

  // 횟수 컨트롤러
  final _aCtrl     = TextEditingController(text: '20');
  final _jCtrl     = TextEditingController(text: '10');
  final _qCtrl     = TextEditingController(text: '12');
  final _kCtrl     = TextEditingController(text: '15');
  final _jokerCtrl = TextEditingController(text: '30');

  // 문양 매핑 컨트롤러
  final _spadeCtrl   = TextEditingController(text: '푸시업'); // ♠ 검정
  final _diamondCtrl = TextEditingController(text: '스쿼트'); // ♦ 빨강
  final _heartCtrl   = TextEditingController(text: '버피');   // ♥ 빨강
  final _clubCtrl    = TextEditingController(text: '런지');   // ♣ 검정

  // 문양 입력 에러 상태(빈칸 검증용)
  bool _errDiamond = false;
  bool _errHeart   = false;
  bool _errSpade   = false;
  bool _errClub    = false;

  // 스낵바(토스트) 스로틀
  DateTime? _lastToastAt;

  // 저장 키
  static const _kPreset    = 'settings.preset';
  static const _kA         = 'settings.A';
  static const _kJ         = 'settings.J';
  static const _kQ         = 'settings.Q';
  static const _kK         = 'settings.K';
  static const _kJoker     = 'settings.Joker';
  static const _kRest      = 'settings.Rest';
  static const _kTotalSets = 'settings.TotalSets';

  static const _kSpade   = 'settings.Spade';
  static const _kDiamond = 'settings.Diamond';
  static const _kHeart   = 'settings.Heart';
  static const _kClub    = 'settings.Club';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    // 입력 시 에러 해제
    _diamondCtrl.addListener(() => _clearErrorIfFilled('diamond'));
    _heartCtrl.addListener(() => _clearErrorIfFilled('heart'));
    _spadeCtrl.addListener(() => _clearErrorIfFilled('spade'));
    _clubCtrl.addListener(() => _clearErrorIfFilled('club'));
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

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();

    _preset = Preset.values[sp.getInt(_kPreset) ?? Preset.beginner.index];

    final base = _defaults[Preset.beginner]!;
    final a     = sp.getInt(_kA)         ?? base['A']!;
    final j     = sp.getInt(_kJ)         ?? base['J']!;
    final q     = sp.getInt(_kQ)         ?? base['Q']!;
    final k     = sp.getInt(_kK)         ?? base['K']!;
    final joker = sp.getInt(_kJoker)     ?? base['Joker']!;
    final rest  = sp.getInt(_kRest)      ?? base['Rest']!;
    final sets  = sp.getInt(_kTotalSets) ?? base['TotalSets']!;

    final spade   = sp.getString(_kSpade)   ?? '푸시업';
    final diamond = sp.getString(_kDiamond) ?? '스쿼트';
    final heart   = sp.getString(_kHeart)   ?? '버피';
    final club    = sp.getString(_kClub)    ?? '런지';

    setState(() {
      _aCtrl.text = '$a';
      _jCtrl.text = '$j';
      _qCtrl.text = '$q';
      _kCtrl.text = '$k';
      _jokerCtrl.text = '$joker';
      _restSec = rest.toDouble();
      _totalSets = sets.clamp(1, 54); // 안전장치

      _spadeCtrl.text = spade;
      _diamondCtrl.text = diamond;
      _heartCtrl.text = heart;
      _clubCtrl.text = club;

      _dirty = false; // 로드 직후는 깨끗
    });

    _ensureCustomIfMismatched(); // preset 표시만 맞춤(저장은 하지 않음)
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kPreset, _preset.index);

    await sp.setInt(_kA,     _parseOr(_aCtrl.text, 0));
    await sp.setInt(_kJ,     _parseOr(_jCtrl.text, 0));
    await sp.setInt(_kQ,     _parseOr(_qCtrl.text, 0));
    await sp.setInt(_kK,     _parseOr(_kCtrl.text, 0));
    await sp.setInt(_kJoker, _parseOr(_jokerCtrl.text, 0));
    await sp.setInt(_kRest,  _restSec.round());
    await sp.setInt(_kTotalSets, _totalSets.clamp(1, 54));

    await sp.setString(_kSpade,   _spadeCtrl.text.trim());
    await sp.setString(_kDiamond, _diamondCtrl.text.trim());
    await sp.setString(_kHeart,   _heartCtrl.text.trim());
    await sp.setString(_kClub,    _clubCtrl.text.trim());
  }

  void _applyPreset(Preset p) {
    if (p == Preset.custom) {
      setState(() => _preset = p);
      _dirty = true; // 저장은 하지 않음
      return;
    }
    final m = _defaults[p]!;
    setState(() {
      _preset = p;
      _aCtrl.text     = '${m['A']}';
      _jCtrl.text     = '${m['J']}';
      _qCtrl.text     = '${m['Q']}';
      _kCtrl.text     = '${m['K']}';
      _jokerCtrl.text = '${m['Joker']}';
      _restSec        = (m['Rest'] as int).toDouble();
      _totalSets      = m['TotalSets'] as int; // 프리셋에 맞게 세트도 적용
      _dirty = true;
    });
  }

  void _markCustomAfterChangeNumeric() {
    if (_preset != Preset.custom) {
      setState(() => _preset = Preset.custom);
    }
    _dirty = true; // 저장 X
  }

  void _ensureCustomIfMismatched() {
    if (_preset == Preset.custom) return;
    final m = _defaults[_preset]!;
    final a     = _parseOr(_aCtrl.text, 0);
    final j     = _parseOr(_jCtrl.text, 0);
    final q     = _parseOr(_qCtrl.text, 0);
    final k     = _parseOr(_kCtrl.text, 0);
    final joker = _parseOr(_jokerCtrl.text, 0);
    final rest  = _restSec.round();
    final sets  = _totalSets;

    final same = (a == m['A'] &&
                  j == m['J'] &&
                  q == m['Q'] &&
                  k == m['K'] &&
                  joker == m['Joker'] &&
                  rest == m['Rest'] &&
                  sets == m['TotalSets']);
    if (!same) {
      setState(() => _preset = Preset.custom);
      _dirty = true; // 저장 X
    }
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

  // 문양 텍스트 onChanged (8글자 제한 안내 + 커스텀 전환) — 저장하지 않음
  void _onSuitChanged(String value) {
    if (value.length == 8) {
      _showToast('최대 8글자까지 입력할 수 있어요.');
    }
    if (_preset != Preset.custom) {
      setState(() => _preset = Preset.custom);
    }
    _dirty = true; // 저장 X
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              child: SegmentedButton<Preset>(
                segments: const [
                  ButtonSegment(value: Preset.beginner, label: Text('초보', style:TextStyle(fontSize: 14)),   icon: Icon(Icons.flag)),
                  ButtonSegment(value: Preset.normal,   label: Text('기본', style:TextStyle(fontSize: 14)),   icon: Icon(Icons.star_half)),
                  ButtonSegment(value: Preset.hard,     label: Text('하드', style:TextStyle(fontSize: 14)),   icon: Icon(Icons.whatshot)),
                  ButtonSegment(value: Preset.custom,   label: Text('커스텀', style:TextStyle(fontSize: 14)), icon: Icon(Icons.tune)),
                ],
                selected: {_preset},
                onSelectionChanged: (s) => _applyPreset(s.first),
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
                  Text('${_restSec.round()} 초', style: Theme.of(context).textTheme.bodyLarge),
                  Slider(
                    value: _restSec,
                    min: 0,
                    max: 90,
                    divisions: 18,
                    label: '${_restSec.round()}초',
                    onChanged: (v) {
                      setState(() => _restSec = v);
                      _markCustomAfterChangeNumeric();
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
                      value: _totalSets.toDouble(),
                      min: 1,
                      max: 54,
                      divisions: 53,
                      label: "$_totalSets 장",
                      onChanged: (v) {
                        setState(() => _totalSets = v.round());
                        _markCustomAfterChangeNumeric();
                      },
                    ),
                  ),
                  Text("$_totalSets 장", style: const TextStyle(fontSize: 16)),
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
                    onChanged: (_) => _markCustomAfterChangeNumeric(),
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'J',
                    controller: _jCtrl,
                    onChanged: (_) => _markCustomAfterChangeNumeric(),
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'Q',
                    controller: _qCtrl,
                    onChanged: (_) => _markCustomAfterChangeNumeric(),
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'K',
                    controller: _kCtrl,
                    onChanged: (_) => _markCustomAfterChangeNumeric(),
                    toast: _showToast,
                  ),
                  const Divider(height: 12),
                  _NumberRow(
                    label: 'Joker',
                    controller: _jokerCtrl,
                    onChanged: (_) => _markCustomAfterChangeNumeric(),
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
              onPressed: () async {
                if (!_validateSuits()) return;

                _ensureCustomIfMismatched(); // 표시만 맞추기
                await _savePrefs();          // ← 저장은 여기서만!
                _dirty = false;

                _showToast('저장되었습니다');
                if (mounted) Navigator.pop(context); // 닫기
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
  final ValueChanged<String> onChanged; // 길이 8 안내 및 커스텀 전환
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
              onChanged(v); // preset → custom 전환 등 (저장 X)
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