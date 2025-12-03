import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/settings_keys.dart';
import '../models/workout_settings.dart';

/// 설정 저장/로드 Repository
class SettingsRepository {
  Future<WorkoutSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultSettings = WorkoutSettings.beginner();

    return WorkoutSettings(
      aCount: prefs.getInt(SettingsKeys.aCount) ?? defaultSettings.aCount,
      jCount: prefs.getInt(SettingsKeys.jCount) ?? defaultSettings.jCount,
      qCount: prefs.getInt(SettingsKeys.qCount) ?? defaultSettings.qCount,
      kCount: prefs.getInt(SettingsKeys.kCount) ?? defaultSettings.kCount,
      jokerCount: prefs.getInt(SettingsKeys.jokerCount) ?? defaultSettings.jokerCount,
      restSeconds: prefs.getInt(SettingsKeys.restSeconds) ?? defaultSettings.restSeconds,
      totalSets: prefs.getInt(SettingsKeys.totalSets) ?? defaultSettings.totalSets,
      spadeExercise: prefs.getString(SettingsKeys.spadeExercise) ?? defaultSettings.spadeExercise,
      diamondExercise: prefs.getString(SettingsKeys.diamondExercise) ?? defaultSettings.diamondExercise,
      heartExercise: prefs.getString(SettingsKeys.heartExercise) ?? defaultSettings.heartExercise,
      clubExercise: prefs.getString(SettingsKeys.clubExercise) ?? defaultSettings.clubExercise,
    );
  }

  Future<void> saveSettings(WorkoutSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(SettingsKeys.aCount, settings.aCount),
      prefs.setInt(SettingsKeys.jCount, settings.jCount),
      prefs.setInt(SettingsKeys.qCount, settings.qCount),
      prefs.setInt(SettingsKeys.kCount, settings.kCount),
      prefs.setInt(SettingsKeys.jokerCount, settings.jokerCount),
      prefs.setInt(SettingsKeys.restSeconds, settings.restSeconds),
      prefs.setInt(SettingsKeys.totalSets, settings.totalSets),
      prefs.setString(SettingsKeys.spadeExercise, settings.spadeExercise),
      prefs.setString(SettingsKeys.diamondExercise, settings.diamondExercise),
      prefs.setString(SettingsKeys.heartExercise, settings.heartExercise),
      prefs.setString(SettingsKeys.clubExercise, settings.clubExercise),
    ]);
  }

  Future<int> loadPresetIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(SettingsKeys.preset) ?? 0;
  }

  Future<void> savePresetIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.preset, index);
  }
}
