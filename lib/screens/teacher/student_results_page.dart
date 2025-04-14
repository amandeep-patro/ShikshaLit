import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StudentResultsPage extends StatelessWidget {
  final DocumentSnapshot student;
  
  const StudentResultsPage({Key? key, required this.student}) : super(key: key);

  static const Map<String, Color> kColorScheme = {
    'primary': Color.fromARGB(255, 42, 6, 92),
    'success': Color.fromARGB(255, 131, 184, 133),
    'warning': Color.fromARGB(255, 216, 175, 112),
    'error': Color.fromARGB(255, 207, 108, 107),
    'background': Color(0xFFF5F5F5),
  };

  String _formatTitle(String key) {
  // Split by camelCase
  final words = key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  
  // Capitalize first letter of each word
  return words.split(' ')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

  Color _getColorForScore(double score) {
    if (score >= 75) return kColorScheme['success']!;
    if (score >= 50) return kColorScheme['warning']!;
    return kColorScheme['error']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Results'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('results')
            .doc(student['studentId'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading results'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No results found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final components = Map<String, int>.from(data['components']);
          final categories = Map<String, int>.from(data['categories']);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Component Scores',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kColorScheme['primary'],
                  ),
                ),
                SizedBox(height: 12),
                ...components.entries.map((e) => _buildScoreCard(
                      _formatTitle(e.key),
                      e.value.toDouble(),
                      description: 'Component score for ${_formatTitle(e.key)}',
                    )),
                SizedBox(height: 24),
                Text(
                  'Category Scores',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kColorScheme['primary'],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barGroups: categories.entries
                          .map((e) => BarChartGroupData(
                                x: categories.keys.toList().indexOf(e.key),
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.toDouble(),
                                    color: _getColorForScore(e.value.toDouble()),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ))
                          .toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final categories = ['Reading', 'Writing', 'Speaking', 'Understanding'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  categories[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kColorScheme['primary'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(String title, double score, {String? description}) {
    final color = _getColorForScore(score);
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kColorScheme['primary'],
              ),
            ),
            if (description != null) ...[
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  '${score.toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}