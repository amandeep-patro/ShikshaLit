import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:literacy_check/services/scores_service.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class ImageRecognitionScreen extends StatefulWidget {
  @override
  _ImageRecognitionScreenState createState() => _ImageRecognitionScreenState();
}

class _ImageRecognitionScreenState extends State<ImageRecognitionScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('literacycheck')
              .doc('image_recognition')
              .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['questions'] != null) {
          // Create a new list from the fetched questions
          List<Map<String, dynamic>> allQuestions =
              List<Map<String, dynamic>>.from(data['questions']);

          // Shuffle all questions
          allQuestions.shuffle(Random());

          setState(() {
            // Take only 5 questions for this session
            questions = allQuestions.take(5).toList();

            // Also shuffle the options for each question
            for (var question in questions) {
              List<String> options = List<String>.from(question['options']);
              options.shuffle(Random());
              question['options'] = options;
            }

            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  void _finishTest() async {
    // Calculate score out of 100
    final finalScore = (score / questions.length * 100).round();

    // Save score using ScoresService
    await ScoresService.saveTestScore('imagerecog', finalScore);

    // Save completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('imagerecog-completed', true);

    // Return score to previous screen
    Navigator.pop(context, finalScore);
  }

  void checkAnswer(String selected) {
    String correct = questions[currentQuestionIndex]['correctAnswer'] ?? '';
    bool isCorrect = selected == correct;

    if (isCorrect) {
      score++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Correct ✅' : 'Wrong ❌'),
        duration: Duration(milliseconds: 800),
      ),
    );

    Future.delayed(Duration(milliseconds: 900), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
      } else {
        _finishTest(); // Changed from _finishQuiz to _finishTest
      }
    });
  }

  // When restarting the quiz, also reshuffle the questions
  void restartQuiz() {
    setState(() {
      questions.shuffle(Random());
      // Shuffle options for each question again
      for (var question in questions) {
        List<String> options = List<String>.from(question['options']);
        options.shuffle(Random());
        question['options'] = options;
      }
      currentQuestionIndex = 0;
      score = 0;
      showResult = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Image Recognition')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Recognition'),
        backgroundColor: Colors.deepPurple,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Question ${currentQuestionIndex + 1} of ${questions.length}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Image.network(
              question['imageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Icon(Icons.broken_image, size: 100),
            ),
            SizedBox(height: 24),
            ...List.generate(4, (index) {
              final option = question['options'][index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () => checkAnswer(option),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
