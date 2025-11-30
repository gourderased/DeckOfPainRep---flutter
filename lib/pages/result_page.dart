import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final int totalSeconds;                      // 총 운동 시간(초)
  final Map<String, int> countsByExercise;     // 운동명 → 총 횟수
  final int totalCards;                        // 완료 카드 수
  final Map<String, String> exerciseToSuit;    // 운동명 → 'spade'|'diamond'|'heart'|'clover'

  const ResultPage({
    super.key,
    required this.totalSeconds,
    required this.countsByExercise,
    required this.totalCards,
    required this.exerciseToSuit,
  });

  // mm:ss
  String _formatMMSS(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // 무늬 텍스트 아이콘(이모지) + 색상
  Widget _suitIcon(String? suit) {
    const ts = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
    switch (suit) {
      case 'diamond':
        return Text('♦', style: ts.copyWith(color: const Color(0xFFE53935))); // 빨강
      case 'heart':
        return Text('♥', style: ts.copyWith(color: const Color(0xFFE53935))); // 빨강
      case 'spade':
        return Text('♠', style: ts.copyWith(color: const Color(0xFFBDBDBD))); // 밝은 회색
      case 'clover':
        return Text('♣', style: ts.copyWith(color: const Color(0xFFBDBDBD))); // 밝은 회색
      default:
        return const Icon(Icons.fitness_center, color: Colors.white70);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ----- 정렬: 다이아 ▶ 하트 ▶ 스페이드 ▶ 클로버 -----
    const suitOrder = ['diamond', 'heart', 'spade', 'clover'];
    final items = countsByExercise.entries.toList()
      ..sort((a, b) {
        final sa = exerciseToSuit[a.key] ?? '~';
        final sb = exerciseToSuit[b.key] ?? '~';
        final ia = suitOrder.indexOf(sa);
        final ib = suitOrder.indexOf(sb);
        if (ia != ib) return ia.compareTo(ib);
        // 같은 무늬면 이름으로 정렬(가나다/알파벳)
        return a.key.compareTo(b.key);
      });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0C0C),
        foregroundColor: Colors.white,
        title: const Text('오늘의 운동 결과'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // 상단 요약 카드(시간/완료 카드 수)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 6,
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _StatRow(icon: Icons.timer, label: "총 운동 시간", value: _formatMMSS(totalSeconds)),
                      const SizedBox(height: 12),
                      _StatRow(icon: Icons.check_circle, label: "완료 카드 수", value: "$totalCards 장"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 섹션 타이틀
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "운동별 횟수",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // 리스트
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 3,
                  color: Colors.white.withOpacity(0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white24, height: 1),
                    itemBuilder: (_, i) {
                      final e = items[i];
                      if (e.value == 0) return const SizedBox.shrink();
                      final suit = exerciseToSuit[e.key]; // 운동명으로 무늬 조회
                      return ListTile(
                        leading: _suitIcon(suit),
                        title: Text(
                          e.key,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          "${e.value}회",
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('홈으로 가기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 요약 행
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}