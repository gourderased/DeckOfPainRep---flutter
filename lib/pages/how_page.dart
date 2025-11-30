import 'package:flutter/material.dart';

class HowPage extends StatelessWidget {
  const HowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 방법'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 내용은 스크롤
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 인트로
                    Text(
                      'Deck of Pain 이란?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '총 54장의 카드(조커 포함)를 섞어서 뽑히는 카드에 따라 '
                      '맨몸 운동을 수행하는 방식입니다. 종목/횟수/세트는 설정에서 조절할 수 있습니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    // 기본 규칙
                    const SizedBox(height: 16),
                    Text('기본 규칙', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    const _RuleRow(
                      icon: Icons.style,
                      title: '카드 = 운동 지시',
                      subtitle: '무늬(문양)에 따라 운동 종목이 정해지고, 그림/에이스/조커는 고정 횟수로 수행합니다.',
                    ),
                    const _RuleRow(
                      icon: Icons.timer,
                      title: '휴식 타이머',
                      subtitle: '각 카드 수행 후 짧게 휴식합니다. 휴식 시간은 설정에서 변경할 수 있습니다.',
                    ),
                    const _RuleRow(
                      icon: Icons.track_changes,
                      title: '진행률 표시',
                      subtitle: '설정한 “총 세트 수(카드 장수)” 기준으로 진행률을 표시합니다.',
                    ),

                    const SizedBox(height: 16),
                    // 팁
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates, color: cs.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '팁: 초보/기본/하드 프리셋으로 시작해 보고, 컨디션에 맞춰 '
                              '세트 수(카드 장수)와 휴식 시간을 조정해 보세요.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 프리셋 안내 (세트 수 포함 / 숫자카드 규칙 제거)
                    const SizedBox(height: 24),
                    Text('프리셋 안내', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),

                    // 초보
                    const _RuleRow(
                      icon: Icons.flag,
                      title: '초보',
                      subtitle:
                          '세트 수: 20장\n'
                          '그림/조커/에이스 기준 횟수: J=10 · Q=12 · K=15 · A=20 · Joker=30\n'
                          '휴식: 30초\n'
                          '처음 시작하는 분들께 권장합니다.',
                    ),
                    // 기본
                    const _RuleRow(
                      icon: Icons.star_half,
                      title: '기본',
                      subtitle:
                          '세트 수: 36장\n'
                          '그림/조커/에이스 기준 횟수: J=15 · Q=20 · K=25 · A=30 · Joker=40\n'
                          '휴식: 45초\n'
                          '평소 운동을 꾸준히 하는 분들께 권장합니다.',
                    ),
                    // 하드
                    const _RuleRow(
                      icon: Icons.whatshot,
                      title: '하드',
                      subtitle:
                          '세트 수: 54장(풀 덱)\n'
                          '그림/조커/에이스 기준 횟수: J=20 · Q=25 · K=30 · A=40 · Joker=50\n'
                          '휴식: 30초\n'
                          '고강도 챌린지를 원하는 분들께 권장합니다.',
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // 하단 고정 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pushNamed(context, '/card'),
                  child: const Text('바로 시작하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 공통 항목 행
class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RuleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurface.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}