import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DartCodeExecutionPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Push sample data to 'example' collection
  Future<void> _pushDataToDatabase() async {
    try {
      await _firestore.collection('example').add({
        'name': 'Sample Data',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Data pushed successfully!');
    } catch (e) {
      print('Error pushing data: $e');
    }
  }

  // List of word reading questions
  final List<Map<String, dynamic>> wordReadingQuestions = [
    {
      "word": "cat",
      "textToSpeak": "Can you read this word?",
      "expectedAnswer": "cat"
    },
    {
      "word": "dog",
      "textToSpeak": "Please read the word shown.",
      "expectedAnswer": "dog"
    },
    {
      "word": "sun",
      "textToSpeak": "What is this word?",
      "expectedAnswer": "sun"
    },
    {
      "word": "book",
      "textToSpeak": "Try to read this word.",
      "expectedAnswer": "book"
    },
    {
      "word": "fish",
      "textToSpeak": "Read the word on the screen.",
      "expectedAnswer": "fish"
    },
    {
      "word": "ball",
      "textToSpeak": "Can you say this word?",
      "expectedAnswer": "ball"
    },
    {
      "word": "tree",
      "textToSpeak": "Read aloud the word displayed.",
      "expectedAnswer": "tree"
    },
    {
      "word": "milk",
      "textToSpeak": "Try to read the word out loud.",
      "expectedAnswer": "milk"
    },
    {
      "word": "hat",
      "textToSpeak": "What word do you see?",
      "expectedAnswer": "hat"
    },
    {
      "word": "car",
      "textToSpeak": "Say this word.",
      "expectedAnswer": "car"
    },
    
  ];

  // Push word reading test data to Firestore
  Future<void> uploadWordReadingTest() async {
    final collection = _firestore
        .collection('tests')
        .doc('test2_word_reading')
        .collection('questions');

    try {
      for (var question in wordReadingQuestions) {
        await collection.add(question);
      }
      print('Word reading test uploaded successfully!');
    } catch (e) {
      print('❌ Failed to upload word reading test: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Run Dart Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Click a button below to run Dart code and push data to Firestore.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload),
              label: Text('Push Sample Data'),
              onPressed: _pushDataToDatabase,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.quiz),
              label: Text('Upload Word Reading Test'),
              onPressed: uploadWordReadingTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
