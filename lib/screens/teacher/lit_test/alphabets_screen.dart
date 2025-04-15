import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:literacy_check/services/scores_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class AlphabetsScreen extends StatefulWidget {
  @override
  _AlphabetsScreenState createState() => _AlphabetsScreenState();
}

class _AlphabetsScreenState extends State<AlphabetsScreen> {
  List<String> allAlphabets = [];
  List<String> questions = [];
  int currentQuestionIndex = 0;
  String displayText = '';
  bool isLoading = true;
  bool isShowingResult = false;
  bool isCorrect = false;
  int correctCount = 0;
  FlutterTts flutterTts = FlutterTts();
  List<String> currentOptions = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchItems();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-IN");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void _finishTest() async {
    final score = (correctCount / questions.length * 100).round();

    // Save score using ScoresService
    await ScoresService.saveTestScore('alphabets', score);

    // Save completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alphabets-completed', true);

    Navigator.pop(context, score);
  }

  Future<void> _fetchItems() async {
    setState(() {
      isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('literacycheck')
          .doc('alphabets')
          .get();

      final data = doc.data();
      if (data != null && data['items'] is List) {
        setState(() {
          allAlphabets = List<String>.from(data['items'])
              .where((item) => item.length == 1) // Only single letters
              .toList();
          
          // Generate 5 random questions
          questions = (List<String>.from(allAlphabets)..shuffle()).take(5).toList();
          displayText = questions[currentQuestionIndex];
          
          // Generate options for the first question
          _generateOptions();
          
          isLoading = false;
        });
        
        // Speak the first letter
        _speakCurrentLetter();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _generateOptions() {
    // Create a list of 4 options including the correct answer
    currentOptions = [];
    
    // Add the correct answer
    currentOptions.add(displayText);
    
    // Add 3 random incorrect options
    List<String> availableOptions = List<String>.from(allAlphabets)
        .where((item) => item != displayText)
        .toList();
    availableOptions.shuffle();
    
    currentOptions.addAll(availableOptions.take(3));
    
    // Shuffle the options so the correct answer isn't always in the same position
    currentOptions.shuffle();
  }

  Future<void> _speakCurrentLetter() async {
    await flutterTts.speak(displayText);
  }

  void _checkAnswer(String selectedOption) {
    setState(() {
      isCorrect = selectedOption == displayText;
      if (isCorrect) {
        correctCount++;
      }
      isShowingResult = true;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        displayText = questions[currentQuestionIndex];
        isShowingResult = false;
        
        // Generate new options for the next question
        _generateOptions();
      });
      
      // Speak the new letter
      _speakCurrentLetter();
    } else {
      _finishTest();
    }
  }

  Future<bool> _onWillPop() async => false;

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

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Alphabet Recognition',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
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
        backgroundColor: Colors.blue.shade50,
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Progress bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        questions.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: MediaQuery.of(context).size.width /
                              (questions.length + 2),
                          height: 8,
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
                          // Alphabet card
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
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 32),
                                  Text(
                                    "Listen to the letter",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _speakCurrentLetter,
                                    icon: Icon(Icons.volume_up),
                                    label: Text('Hear Again'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Result animations or multiple choice options
                          if (isShowingResult) ...[
                            Container(
                              height: 150,
                              width: 150,
                              child: isCorrect
                                  ? Lottie.asset('assets/animations/correct.json')
                                  : Lottie.asset('assets/animations/incorrect.json'),
                            ),
                            SizedBox(height: 16),
                            Text(
                              isCorrect ? 'Correct! 🎉' : 'Not quite right 🤔',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? Colors.green : Colors.orange,
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                currentQuestionIndex < questions.length - 1
                                    ? 'Next Question'
                                    : 'Finish Challenge',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ] else ...[
                            // Multiple choice options grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: currentOptions.length,
                              itemBuilder: (context, index) {
                                return ElevatedButton(
                                  onPressed: () => _checkAnswer(currentOptions[index]),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blue.shade800,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.blue.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    padding: EdgeInsets.all(20),
                                    elevation: 3,
                                  ),
                                  child: Text(
                                    currentOptions[index].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Select the correct letter',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade700,
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