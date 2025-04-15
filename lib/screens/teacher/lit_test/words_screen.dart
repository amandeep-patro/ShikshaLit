import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../../../services/scores_service.dart';

class WordsScreen extends StatefulWidget {
  @override
  _WordsScreenState createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen>
    with SingleTickerProviderStateMixin {
  // Same variables as alphabets_screen.dart
  late FlutterSoundRecorder _recorder;
  String? audioPath;
  bool isRecording = false;
  bool hasRecorded = false;
  bool isShowingResult = false;
  List<String> items = [];
  List<String> questions = [];
  int currentQuestionIndex = 0;
  String displayText = '';
  String transcribedText = '';
  int correctCount = 0;
  bool isLoading = true;
  bool isCorrect = false;
  late AnimationController _micAnimationController;

  // Remove unused sentencePercentages list since this is for alphabets only

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _initializeRecorder();
    _fetchItems();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  Future<void> toggleRecording() async {
    if (!isRecording) {
      final dir = await getTemporaryDirectory();
      audioPath = '${dir.path}/recording.aac';
      await _recorder.startRecorder(toFile: audioPath);
      setState(() => isRecording = true);
      _micAnimationController.repeat(reverse: true);
    } else {
      await _recorder.stopRecorder();
      _micAnimationController.stop();
      _micAnimationController.reset();
      setState(() {
        isRecording = false;
        hasRecorded = true;
      });
      await _transcribeAudio();
    }
  }

  Future<void> _transcribeAudio() async {
    if (audioPath == null) return;

    setState(() {
      isLoading = true;
    });

    final file = File(audioPath!);
    final bytes = await file.readAsBytes();
    final url = Uri.parse('https://api.deepgram.com/v1/listen');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token ${dotenv.env['DEEPGRAM_API'] ?? ''}',
          'Content-Type': 'audio/aac',
        },
        body: bytes,
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['results'] != null) {
        final transcript =
            jsonResponse['results']['channels'][0]['alternatives'][0]['transcript'];

        setState(() {
          transcribedText =
              transcript.isEmpty ? 'No speech detected' : transcript;

          String normalizedTranscribed = _normalizeText(transcribedText);
          String normalizedDisplay = _normalizeText(displayText);

          isCorrect = normalizedTranscribed == normalizedDisplay;
          if (isCorrect) {
            correctCount++;
          }

          isShowingResult = true;
          isLoading = false;
        });
      } else {
        setState(() {
          transcribedText = 'Transcription error: No results';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        transcribedText = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _calculateSentenceMatch(String expected, String actual) {
    String normExpected = _normalizeText(expected);
    String normActual = _normalizeText(actual);
    int maxLength =
        normExpected.length > normActual.length
            ? normExpected.length
            : normActual.length;
    if (maxLength == 0) return 100.0;
    int distance = _levenshteinDistance(normExpected, normActual);
    double similarity = (1 - distance / maxLength) * 100;
    return similarity.clamp(0.0, 100.0);
  }

  int _levenshteinDistance(String s1, String s2) {
    List<List<int>> dp = List.generate(
      s1.length + 1,
      (_) => List<int>.filled(s2.length + 1, 0),
    );
    for (int i = 0; i <= s1.length; i++) dp[i][0] = i;
    for (int j = 0; j <= s2.length; j++) dp[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[s1.length][s2.length];
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        displayText = questions[currentQuestionIndex];
        transcribedText = '';
        hasRecorded = false;
        isShowingResult = false;
      });
    } else {
      _finishTest(); // Changed from _saveResultsAndReturn to _finishTest
    }
  }

  Future<void> _finishTest() async {
    // Calculate score out of 100
    final score = (correctCount / questions.length * 100).round();

    // Save score using ScoresService
    await ScoresService.saveTestScore('words', score);

    // Save completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('words-completed', true);

    Navigator.pop(context, score);
  }

  Future<bool> _onWillPop() async => false;

  @override
  void dispose() {
    _recorder.closeRecorder();
    _micAnimationController.dispose();
    super.dispose();
  }

  Color _getProgressColor(int index) {
    if (index < currentQuestionIndex) {
      // Completed question
      return Colors.blue;
    } else if (index == currentQuestionIndex) {
      // Current question
      return Colors.amber;
    } else {
      // Upcoming question
      return Colors.grey.shade300;
    }
  }

  // Modify _fetchItems for words
  Future<void> _fetchItems() async {
    setState(() {
      isLoading = true;
    });
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('literacycheck')
              .doc('words')
              .get();

      final data = doc.data();
      if (data != null && data['items'] is List) {
        setState(() {
          items =
              List<String>.from(data['items'])
                  .where((item) => !item.contains(' ')) // Single words only
                  .toList();
          questions = (items..shuffle()).take(5).toList();
          displayText = questions[currentQuestionIndex];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Word Recognition'),
          backgroundColor: Colors.green.shade700,
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Are you sure?'),
                    content: Text(
                      'You will lose your progress if you exit now.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Stay'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text('Exit'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Exit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade50,
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Progress bar
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          questions.length,
                          (index) => Container(
                            width: 40,
                            height: 8,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _getProgressColor(index),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Question Card
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Text(
                                      'Question ${currentQuestionIndex + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 32),
                                    Text(
                                      displayText,
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 32),

                            // Recording button
                            GestureDetector(
                              onTap: toggleRecording,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color:
                                      isRecording ? Colors.red : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: AnimatedBuilder(
                                    animation: _micAnimationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale:
                                            1.0 +
                                            (_micAnimationController.value *
                                                0.2),
                                        child: Icon(
                                          Icons.mic,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 16),
                            Text(
                              isRecording ? 'Recording...' : 'Tap to Record',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                            ),

                            if (isShowingResult) ...[
                              SizedBox(height: 24),
                              Container(
                                height: 100,
                                width: 100,
                                child:
                                    isCorrect
                                        ? Lottie.asset(
                                          'assets/animations/correct.json',
                                        )
                                        : Lottie.asset(
                                          'assets/animations/incorrect.json',
                                        ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                isCorrect ? 'Correct!' : 'Try Again',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect ? Colors.green : Colors.red,
                                ),
                              ),
                              if (!isCorrect && transcribedText.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  'You said: $transcribedText',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _nextQuestion,
                                child: Text(
                                  currentQuestionIndex < questions.length - 1
                                      ? 'Next Word'
                                      : 'Finish',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
