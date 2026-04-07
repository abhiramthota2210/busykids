import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static ScoreService? _instance;
  static ScoreService get instance => _instance ??= ScoreService._();
  ScoreService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<int> getHighScore(String key) async {
    await init();
    return _prefs?.getInt(key) ?? 0;
  }

  Future<bool> saveIfHighScore(String key, int score) async {
    await init();
    final current = _prefs?.getInt(key) ?? 0;
    if (score > current) {
      await _prefs?.setInt(key, score);
      return true;
    }
    return false;
  }

  Future<Map<String, int>> getAllHighScores(List<String> keys) async {
    await init();
    return {for (final k in keys) k: _prefs?.getInt(k) ?? 0};
  }
}