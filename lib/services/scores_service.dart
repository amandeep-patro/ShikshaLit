import 'package:shared_preferences/shared_preferences.dart';

class ScoresService {
  static const String _prefix = 'test_score_';
  
  static Future<void> saveTestScore(String testName, int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$testName', score);
  }

  static Future<Map<String, int>> getAllTestScores() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> scores = {};
    
    final testNames = [
      'alphabets',
      'words', 
      'sentences',
      'comprehension',
      'reading',
      'errorfind',
      'rhyming',
      'spelling',
      'imagerecog'
    ];

    for (var test in testNames) {
      scores[test] = prefs.getInt('$_prefix$test') ?? 0;
    }

    return scores;
  }

  static Future<void> clearAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    final testNames = [
      'alphabets',
      'words', 
      'sentences',
      'comprehension',
      'reading',
      'errorfind',
      'rhyming',
      'spelling',
      'imagerecog'
    ];

    for (var test in testNames) {
      await prefs.remove('$_prefix$test');
    }
  }
}