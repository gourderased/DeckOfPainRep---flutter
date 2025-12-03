/// 운동 결과 모델
class WorkoutResult {
  final int totalSeconds;
  final int totalCards;
  final Map<String, int> countsByExercise;
  final Map<String, String> exerciseToSuit;

  const WorkoutResult({
    required this.totalSeconds,
    required this.totalCards,
    required this.countsByExercise,
    required this.exerciseToSuit,
  });

  String get formattedTime {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get totalReps {
    return countsByExercise.values.fold(0, (sum, count) => sum + count);
  }
}
