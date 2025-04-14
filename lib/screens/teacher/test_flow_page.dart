import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:literacy_check/services/scores_service.dart';

class TestFlowPage extends StatefulWidget {
  final String studentId; // Pass studentId to this screen

  const TestFlowPage({Key? key, required this.studentId}) : super(key: key);

  @override
  _TestFlowPageState createState() => _TestFlowPageState();
}

class _TestFlowPageState extends State<TestFlowPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _testControllers = {};
  Map<String, int> _componentScores = {};
  Map<String, int> _categoryScores = {};
  bool _calculated = false;

  final List<String> _testNames = [
    'alphabetTest',
    'wordTest',
    'sentenceTest',
    'paragraphTest',
    'listeningComprehensionTest',
    'rhymingTest',
    'spellingTest',
    'errorDetectionTest',
    'imageIdentificationTest'
  ];

  @override
  void initState() {
    super.initState();
    for (String test in _testNames) {
      _testControllers[test] = TextEditingController();
    }
    _loadTestScores();
  }

  Future<void> _loadTestScores() async {
    final scores = await ScoresService.getAllTestScores();
    
    setState(() {
      for (var entry in scores.entries) {
        _testControllers[_getTestName(entry.key)]?.text = entry.value.toString();
      }
    });
  }

  String _getTestName(String key) {
    final Map<String, String> testNameMapping = {
      'alphabets': 'alphabetTest',
      'words': 'wordTest',
      'sentences': 'sentenceTest',
      'comprehension': 'listeningComprehensionTest',
      'reading': 'paragraphTest',
      'errorfind': 'errorDetectionTest',
      'rhyming': 'rhymingTest',
      'spelling': 'spellingTest',
      'imagerecog': 'imageIdentificationTest'
    };
    return testNameMapping[key] ?? key;
  }

  @override
  void dispose() {
    for (var controller in _testControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateScores() {
    final Map<String, double> testScores = {};
    bool valid = true;

    for (var test in _testNames) {
      final text = _testControllers[test]!.text.trim();
      if (text.isEmpty) {
        valid = false;
        break;
      }
      final score = double.tryParse(text);
      if (score == null || score < 0 || score > 100) {
        valid = false;
        break;
      }
      testScores[test] = score;
    }

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter valid scores (0–100)")));
      return;
    }

    final componentScores = {
      'pronunciation': ((testScores['sentenceTest']! + testScores['wordTest']! + testScores['paragraphTest']!) / 3).round(),
      'fluency': ((testScores['sentenceTest']! + testScores['wordTest']! + testScores['paragraphTest']!) / 3).round(),
      'activeListening': ((testScores['alphabetTest']! + testScores['listeningComprehensionTest']!) / 2).round(),
      'phonologicalAwareness': ((testScores['sentenceTest']! + testScores['wordTest']! + testScores['paragraphTest']! + testScores['rhymingTest']!) / 4).round(),
      'linguisticAbility': ((testScores['listeningComprehensionTest']! + testScores['spellingTest']! + testScores['errorDetectionTest']!) / 3).round(),
      'visualUnderstanding': testScores['imageIdentificationTest']!.round(),
    };

    final categoryScores = {
      'reading': ((testScores['sentenceTest']! + testScores['wordTest']! + testScores['paragraphTest']!) / 3).round(),
      'writing': ((testScores['spellingTest']! + testScores['errorDetectionTest']! + testScores['rhymingTest']!) / 3).round(),
      'speaking': ((testScores['sentenceTest']! + testScores['wordTest']! + testScores['paragraphTest']!) / 3).round(),
      'understanding': ((testScores['imageIdentificationTest']! + testScores['errorDetectionTest']! + testScores['listeningComprehensionTest']! + testScores['alphabetTest']!) / 4).round(),
    };

    setState(() {
      _componentScores = componentScores;
      _categoryScores = categoryScores;
      _calculated = true;
    });
  }

  Future<void> _saveToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('results').doc(widget.studentId).set({
        'components': _componentScores,
        'categories': _categoryScores,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scores saved successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving scores")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Simulate Test Scores")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Enter Test Scores (out of 100):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._testNames.map((test) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextFormField(
                  controller: _testControllers[test],
                  decoration: InputDecoration(labelText: test),
                  keyboardType: TextInputType.number,
                ),
              )),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _calculateScores,
                child: Text("Calculate Scores"),
              ),
              if (_calculated) ...[
                SizedBox(height: 20),
            Text("Component Scores:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ..._componentScores.entries.map((e) => Text("${e.key}: ${e.value}")), // Removed toStringAsFixed
            SizedBox(height: 12),
            Text("Category Scores:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ..._categoryScores.entries.map((e) => Text("${e.key}: ${e.value}")),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saveToFirestore,
                  icon: Icon(Icons.save),
                  label: Text("Save Scores"),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
