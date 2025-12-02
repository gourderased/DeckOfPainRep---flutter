import 'dart:math';
import '../../data/models/playing_card.dart';
import '../../data/models/workout_settings.dart';

/// 운동 계산 서비스
class WorkoutService {
  final WorkoutSettings settings;
  final Random _random = Random();
  final Map<int, String> _jokerCache = {};

  WorkoutService(this.settings);

  String getExerciseName(PlayingCard card, int deckIndex) {
    if (card.isJoker) {
      return _jokerCache.putIfAbsent(deckIndex, () {
        final pool = card.isRedJoker
            ? [settings.diamondExercise, settings.heartExercise]
            : [settings.spadeExercise, settings.clubExercise];
        return pool[_random.nextInt(pool.length)];
      });
    }

    return switch (card.suit!) {
      Suit.spade => settings.spadeExercise,
      Suit.diamond => settings.diamondExercise,
      Suit.heart => settings.heartExercise,
      Suit.clover => settings.clubExercise,
    };
  }

  int getReps(PlayingCard card) {
    if (card.isJoker) return settings.jokerCount;

    return switch (card.rank) {
      'J' => settings.jCount,
      'Q' => settings.qCount,
      'K' => settings.kCount,
      'A' => settings.aCount,
      _ => int.tryParse(card.rank) ?? 0,
    };
  }

  String getInstruction(PlayingCard card, int deckIndex) {
    final name = getExerciseName(card, deckIndex);
    final reps = getReps(card);
    return '$name - $reps회';
  }

  void clearJokerCache() {
    _jokerCache.clear();
  }
}
