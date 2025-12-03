import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/playing_card.dart';
import '../data/models/workout_settings.dart';
import '../domain/services/deck_service.dart';
import '../domain/services/workout_service.dart';
import 'settings_provider.dart';

/// 운동 상태
enum WorkoutState {
  notStarted,
  working,
  resting,
  readyForNext,
  completed,
}

/// 운동 세션 상태 클래스
class WorkoutSessionState {
  final List<PlayingCard> deck;
  final int currentIndex;
  final int targetCards;
  final WorkoutState state;
  final int restSecondsLeft;
  final DateTime? sessionStartTime;
  final Map<String, int> exerciseCounts;

  const WorkoutSessionState({
    required this.deck,
    required this.currentIndex,
    required this.targetCards,
    required this.state,
    required this.restSecondsLeft,
    this.sessionStartTime,
    required this.exerciseCounts,
  });

  WorkoutSessionState copyWith({
    List<PlayingCard>? deck,
    int? currentIndex,
    int? targetCards,
    WorkoutState? state,
    int? restSecondsLeft,
    DateTime? sessionStartTime,
    Map<String, int>? exerciseCounts,
  }) {
    return WorkoutSessionState(
      deck: deck ?? this.deck,
      currentIndex: currentIndex ?? this.currentIndex,
      targetCards: targetCards ?? this.targetCards,
      state: state ?? this.state,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      exerciseCounts: exerciseCounts ?? this.exerciseCounts,
    );
  }

  PlayingCard? get currentCard =>
      currentIndex >= 0 && currentIndex < deck.length ? deck[currentIndex] : null;

  int get completedCards => currentIndex + 1;
  double get progress => currentIndex < 0 ? 0.0 : (completedCards / targetCards).clamp(0.0, 1.0);
}

/// DeckService Provider
final deckServiceProvider = Provider((ref) => DeckService());

/// WorkoutService Provider (설정 의존)
final workoutServiceProvider = Provider<WorkoutService?>((ref) {
  final settings = ref.watch(settingsProvider);
  return WorkoutService(settings);
});

/// 운동 세션 Notifier
class WorkoutSessionNotifier extends StateNotifier<WorkoutSessionState> {
  final DeckService _deckService;
  final Ref _ref;
  Timer? _restTimer;

  WorkoutSessionNotifier(this._deckService, this._ref)
      : super(WorkoutSessionState(
          deck: [],
          currentIndex: -1,
          targetCards: 20,
          state: WorkoutState.notStarted,
          restSecondsLeft: 0,
          exerciseCounts: {},
        ));

  WorkoutService? get _workoutService => _ref.read(workoutServiceProvider);

  void initializeSession(WorkoutSettings settings) {
    final deck = _deckService.createShuffledDeck();
    state = WorkoutSessionState(
      deck: deck,
      currentIndex: -1,
      targetCards: settings.totalSets.clamp(1, 54),
      state: WorkoutState.notStarted,
      restSecondsLeft: 0,
      exerciseCounts: {},
    );
  }

  void start() {
    if (state.state != WorkoutState.notStarted) return;

    state = state.copyWith(
      sessionStartTime: DateTime.now(),
      currentIndex: 0,
      state: WorkoutState.working,
    );
  }

  void completeCurrentCard() {
    final workoutService = _workoutService;
    if (workoutService == null || state.currentCard == null) return;
    if (state.state != WorkoutState.working) return;

    final card = state.currentCard!;
    final exerciseName = workoutService.getExerciseName(card, state.currentIndex);
    final reps = workoutService.getReps(card);

    final newCounts = Map<String, int>.from(state.exerciseCounts);
    newCounts[exerciseName] = (newCounts[exerciseName] ?? 0) + reps;

    state = state.copyWith(exerciseCounts: newCounts);

    if (state.completedCards >= state.targetCards) {
      state = state.copyWith(state: WorkoutState.completed);
      return;
    }

    _startRest();
  }

  void _startRest() {
    final workoutService = _workoutService;
    if (workoutService == null) return;

    final restSeconds = workoutService.settings.restSeconds;

    if (restSeconds <= 0) {
      state = state.copyWith(state: WorkoutState.readyForNext);
      return;
    }

    state = state.copyWith(
      state: WorkoutState.resting,
      restSecondsLeft: restSeconds,
    );

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restSecondsLeft > 0) {
        state = state.copyWith(restSecondsLeft: state.restSecondsLeft - 1);
      }

      if (state.restSecondsLeft <= 0) {
        timer.cancel();
        state = state.copyWith(state: WorkoutState.readyForNext);
      }
    });
  }

  void nextCard() {
    if (state.state != WorkoutState.readyForNext) return;

    if (state.currentIndex >= state.deck.length - 1 ||
        state.completedCards >= state.targetCards) {
      state = state.copyWith(state: WorkoutState.completed);
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      state: WorkoutState.working,
    );
  }

  String? getCurrentInstruction() {
    final workoutService = _workoutService;
    if (workoutService == null || state.currentCard == null) return null;
    return workoutService.getInstruction(state.currentCard!, state.currentIndex);
  }

  String? getCurrentAssetPath() {
    if (state.currentCard == null) return null;
    return _deckService.getAssetPath(state.currentCard!);
  }

  void reset() {
    _restTimer?.cancel();
    _workoutService?.clearJokerCache();

    state = WorkoutSessionState(
      deck: state.deck,
      currentIndex: -1,
      targetCards: state.targetCards,
      state: WorkoutState.notStarted,
      restSecondsLeft: 0,
      exerciseCounts: {},
    );
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }
}

final workoutSessionProvider =
    StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>((ref) {
  final deckService = ref.watch(deckServiceProvider);
  return WorkoutSessionNotifier(deckService, ref);
});
