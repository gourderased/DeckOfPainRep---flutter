/// 운동 설정 모델
class WorkoutSettings {
  final int aCount;
  final int jCount;
  final int qCount;
  final int kCount;
  final int jokerCount;
  final int restSeconds;
  final int totalSets;
  final String spadeExercise;
  final String diamondExercise;
  final String heartExercise;
  final String clubExercise;

  const WorkoutSettings({
    required this.aCount,
    required this.jCount,
    required this.qCount,
    required this.kCount,
    required this.jokerCount,
    required this.restSeconds,
    required this.totalSets,
    required this.spadeExercise,
    required this.diamondExercise,
    required this.heartExercise,
    required this.clubExercise,
  });

  factory WorkoutSettings.beginner() => const WorkoutSettings(
        aCount: 20,
        jCount: 10,
        qCount: 12,
        kCount: 15,
        jokerCount: 30,
        restSeconds: 30,
        totalSets: 20,
        spadeExercise: '푸시업',
        diamondExercise: '스쿼트',
        heartExercise: '버피',
        clubExercise: '런지',
      );

  factory WorkoutSettings.normal() => const WorkoutSettings(
        aCount: 30,
        jCount: 15,
        qCount: 20,
        kCount: 25,
        jokerCount: 40,
        restSeconds: 45,
        totalSets: 36,
        spadeExercise: '푸시업',
        diamondExercise: '스쿼트',
        heartExercise: '버피',
        clubExercise: '런지',
      );

  factory WorkoutSettings.hard() => const WorkoutSettings(
        aCount: 40,
        jCount: 20,
        qCount: 25,
        kCount: 30,
        jokerCount: 50,
        restSeconds: 30,
        totalSets: 54,
        spadeExercise: '푸시업',
        diamondExercise: '스쿼트',
        heartExercise: '버피',
        clubExercise: '런지',
      );

  WorkoutSettings copyWith({
    int? aCount,
    int? jCount,
    int? qCount,
    int? kCount,
    int? jokerCount,
    int? restSeconds,
    int? totalSets,
    String? spadeExercise,
    String? diamondExercise,
    String? heartExercise,
    String? clubExercise,
  }) {
    return WorkoutSettings(
      aCount: aCount ?? this.aCount,
      jCount: jCount ?? this.jCount,
      qCount: qCount ?? this.qCount,
      kCount: kCount ?? this.kCount,
      jokerCount: jokerCount ?? this.jokerCount,
      restSeconds: restSeconds ?? this.restSeconds,
      totalSets: totalSets ?? this.totalSets,
      spadeExercise: spadeExercise ?? this.spadeExercise,
      diamondExercise: diamondExercise ?? this.diamondExercise,
      heartExercise: heartExercise ?? this.heartExercise,
      clubExercise: clubExercise ?? this.clubExercise,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutSettings) return false;
    return aCount == other.aCount &&
        jCount == other.jCount &&
        qCount == other.qCount &&
        kCount == other.kCount &&
        jokerCount == other.jokerCount &&
        restSeconds == other.restSeconds &&
        totalSets == other.totalSets &&
        spadeExercise == other.spadeExercise &&
        diamondExercise == other.diamondExercise &&
        heartExercise == other.heartExercise &&
        clubExercise == other.clubExercise;
  }

  @override
  int get hashCode {
    return Object.hash(
      aCount,
      jCount,
      qCount,
      kCount,
      jokerCount,
      restSeconds,
      totalSets,
      spadeExercise,
      diamondExercise,
      heartExercise,
      clubExercise,
    );
  }
}
