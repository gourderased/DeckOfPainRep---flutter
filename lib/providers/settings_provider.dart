import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/workout_settings.dart';
import '../data/repositories/settings_repository.dart';

/// 설정 프리셋
enum SettingsPreset {
  beginner,
  normal,
  hard,
  custom;

  String get displayName {
    return switch (this) {
      SettingsPreset.beginner => '초급',
      SettingsPreset.normal => '중급',
      SettingsPreset.hard => '상급',
      SettingsPreset.custom => '커스텀',
    };
  }
}

/// SettingsRepository Provider
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

/// 설정 상태 Provider
class SettingsNotifier extends StateNotifier<WorkoutSettings> {
  final SettingsRepository _repository;
  SettingsPreset _preset = SettingsPreset.beginner;

  SettingsNotifier(this._repository) : super(WorkoutSettings.beginner()) {
    _loadSettings();
  }

  SettingsPreset get preset => _preset;

  Future<void> _loadSettings() async {
    try {
      state = await _repository.loadSettings();
      final presetIndex = await _repository.loadPresetIndex();
      _preset = SettingsPreset.values[presetIndex.clamp(0, 3)];
    } catch (e) {
      state = WorkoutSettings.beginner();
      _preset = SettingsPreset.beginner;
    }
  }

  Future<void> changePreset(SettingsPreset preset) async {
    _preset = preset;

    state = switch (preset) {
      SettingsPreset.beginner => WorkoutSettings.beginner(),
      SettingsPreset.normal => WorkoutSettings.normal(),
      SettingsPreset.hard => WorkoutSettings.hard(),
      SettingsPreset.custom => state,
    };

    await _saveSettings();
  }

  Future<void> updateSettings(WorkoutSettings newSettings) async {
    state = newSettings;
    _ensureCustomIfMismatched();
    await _saveSettings();
  }

  /// 현재 설정이 프리셋과 일치하지 않으면 custom으로 전환
  void _ensureCustomIfMismatched() {
    if (_preset == SettingsPreset.custom) return;

    final expected = switch (_preset) {
      SettingsPreset.beginner => WorkoutSettings.beginner(),
      SettingsPreset.normal => WorkoutSettings.normal(),
      SettingsPreset.hard => WorkoutSettings.hard(),
      SettingsPreset.custom => state,
    };

    // 현재 상태가 프리셋 기본값과 다르면 custom으로 전환
    if (state != expected) {
      _preset = SettingsPreset.custom;
    }
  }

  Future<void> _saveSettings() async {
    await _repository.saveSettings(state);
    await _repository.savePresetIndex(_preset.index);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, WorkoutSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

final presetProvider = Provider<SettingsPreset>((ref) {
  return ref.watch(settingsProvider.notifier).preset;
});
