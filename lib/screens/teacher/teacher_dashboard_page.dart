import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class TeacherDashboard extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? teacherData;
  Map<String, List<double>> componentScores = {};
  Map<String, List<double>> categoryScores = {};
  bool isLoading = true;
  bool isLoadingStudentData = false;
  List<Map<String, dynamic>> studentRankings = [];
  String sortColumn = 'name';
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      setState(() => isLoading = true);

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Query teachers collection where email matches current user's email
      final teacherQuery =
          await _firestore
              .collection('teachers')
              .where('email', isEqualTo: currentUser.email)
              .limit(1)
              .get();

      if (teacherQuery.docs.isNotEmpty) {
        final teacherDoc = teacherQuery.docs.first;
        final data = teacherDoc.data();

        setState(() {
          teacherData = {
            'teacherId': data['teacherId'] ?? '',
            'name': data['name'] ?? 'Not set',
            'email': data['email'] ?? '',
            'role': data['role'] ?? 'Not set',
            'schoolId': data['schoolId'] ?? '',
            'studentIds': data['studentIds'] ?? [],
            'createdAt': data['createdAt']?.toDate().toString() ?? 'Not set',
          };
        });

        // After getting teacher data, load the student assessment data
        await _loadStudentAssessmentData(teacherData!['studentIds']);
      } else {
        print('No teacher found with email: ${currentUser.email}');
      }
      
      // After loading teacher data and student assessments
      await _calculateStudentRankings();
      
    } catch (e) {
      print('Error loading teacher data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadStudentAssessmentData(List<dynamic> studentIds) async {
    try {
      setState(() => isLoadingStudentData = true);

      // Initialize component score lists
      componentScores = {
        'activeListening': [],
        'fluency': [],
        'linguisticAbility': [],
        'phonologicalAwareness': [],
        'pronunciation': [],
        'visualUnderstanding': [],
      };

      // Initialize category score lists
      categoryScores = {
        'reading': [],
        'speaking': [],
        'understanding': [],
        'writing': [],
      };

      // For each student, get their most recent assessment result
      for (var studentId in studentIds) {
        // Query results collection for this student's data, ordered by timestamp
        final resultsQuery =
            await _firestore.collection('results').doc(studentId).get();

        if (resultsQuery.exists) {
          final data = resultsQuery.data()!;

          // Extract component scores if they exist
          if (data['components'] != null) {
            Map<String, dynamic> components = data['components'];

            // Add each component score to our lists
            componentScores.forEach((component, scores) {
              if (components[component] != null) {
                scores.add(components[component].toDouble());
              }
            });
          }

          // Extract category scores if they exist
          if (data['categories'] != null) {
            Map<String, dynamic> categories = data['categories'];

            // Add each category score to our lists
            categoryScores.forEach((category, scores) {
              if (categories[category] != null) {
                scores.add(categories[category].toDouble());
              }
            });
          }
        }
      }

      print('Component scores loaded: ${componentScores.toString()}');
      print('Category scores loaded: ${categoryScores.toString()}');
    } catch (e) {
      print('Error loading student assessment data: $e');
    } finally {
      setState(() => isLoadingStudentData = false);
    }
  }

  Future<void> _calculateStudentRankings() async {
    List<Map<String, dynamic>> rankings = [];

    for (String studentId in teacherData!['studentIds']) {
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();
      final resultsDoc =
          await _firestore.collection('results').doc(studentId).get();

      if (studentDoc.exists && resultsDoc.exists) {
        final studentData = studentDoc.data()!;
        final resultData = resultsDoc.data()!;

        Map<String, dynamic> ranking = {
          'id': studentId,
          'name': studentData['name'] ?? 'Unknown',
          // Categories
          'reading': resultData['categories']?['reading']?.toDouble() ?? 0.0,
          'speaking': resultData['categories']?['speaking']?.toDouble() ?? 0.0,
          'understanding':
              resultData['categories']?['understanding']?.toDouble() ?? 0.0,
          'writing': resultData['categories']?['writing']?.toDouble() ?? 0.0,
          // Components
          'activeListening':
              resultData['components']?['activeListening']?.toDouble() ?? 0.0,
          'fluency': resultData['components']?['fluency']?.toDouble() ?? 0.0,
          'linguisticAbility':
              resultData['components']?['linguisticAbility']?.toDouble() ?? 0.0,
          'phonologicalAwareness':
              resultData['components']?['phonologicalAwareness']?.toDouble() ??
              0.0,
          'pronunciation':
              resultData['components']?['pronunciation']?.toDouble() ?? 0.0,
          'visualUnderstanding':
              resultData['components']?['visualUnderstanding']?.toDouble() ??
              0.0,
        };

        // Calculate average score
        double sum = 0;
        int count = 0;
        ranking.forEach((key, value) {
          if (key != 'id' && key != 'name' && value is double) {
            sum += value;
            count++;
          }
        });
        ranking['average'] = count > 0 ? sum / count : 0.0;

        rankings.add(ranking);
      }
    }

    setState(() {
      studentRankings = rankings;
      _sortRankings();
    });
  }

  void _sortRankings() {
    studentRankings.sort((a, b) {
      if (sortColumn == 'name') {
        return sortAscending
            ? a[sortColumn].toString().compareTo(b[sortColumn].toString())
            : b[sortColumn].toString().compareTo(a[sortColumn].toString());
      }
      return sortAscending
          ? (a[sortColumn] as double).compareTo(b[sortColumn] as double)
          : (b[sortColumn] as double).compareTo(a[sortColumn] as double);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teacher Dashboard')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : teacherData == null
              ? Center(child: Text('No teacher data found'))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teacher Info Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              'Teacher ID',
                              teacherData!['teacherId'],
                            ),
                            _buildInfoRow('Name', teacherData!['name']),
                            _buildInfoRow('Email', teacherData!['email']),
                            _buildInfoRow('Role', teacherData!['role']),
                            _buildInfoRow(
                              'School ID',
                              teacherData!['schoolId'],
                            ),
                            _buildInfoRow(
                              'Created At',
                              teacherData!['createdAt'],
                            ),
                            _buildInfoRow(
                              'Students Assigned',
                              (teacherData!['studentIds'] as List).length
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Stacked Bar Chart for Category Averages
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class Average by Category',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Overall literacy performance across main categories',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            isLoadingStudentData
                                ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                : _buildStackedBarChart(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Class-wide Box Plot Analysis
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Component Distribution Analysis',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Distribution of student scores across literacy components',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            isLoadingStudentData
                                ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                : _buildBoxPlotChart(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Component Correlation Analysis',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Correlation between Fluency and Pronunciation scores',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 16),
                            isLoadingStudentData
                                ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                : _buildScatterPlot(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    _buildRankingTable(),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStackedBarChart() {
    if (categoryScores.isEmpty || _allListsEmpty(categoryScores)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No category data available for your students.'),
        ),
      );
    }

    Map<String, double> categoryAverages = {};
    categoryScores.forEach((category, scores) {
      if (scores.isNotEmpty) {
        double sum = scores.reduce((a, b) => a + b);
        categoryAverages[category] = sum / scores.length;
      } else {
        categoryAverages[category] = 0;
      }
    });

    final Map<String, Color> categoryColors = {
      'reading': const Color.fromARGB(255, 107, 163, 209),
      'speaking': const Color.fromARGB(255, 145, 202, 147),
      'understanding': const Color.fromARGB(255, 221, 180, 118),
      'writing': const Color.fromARGB(255, 198, 124, 211),
    };

    return Container(
      height: 300,
      padding: EdgeInsets.only(top: 20, right: 20, bottom: 20),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          groupsSpace: 40, // Add space between bar groups
          barGroups: [
            _createBarGroup(
              0,
              categoryAverages['reading'] ?? 0,
              Color.fromARGB(255, 107, 163, 209),
              'Reading',
            ),
            _createBarGroup(
              1,
              categoryAverages['speaking'] ?? 0,
              Color.fromARGB(255, 145, 202, 147),
              'Speaking',
            ),
            _createBarGroup(
              2,
              categoryAverages['understanding'] ?? 0,
              Color.fromARGB(255, 221, 180, 118),
              'Understanding',
            ),
            _createBarGroup(
              3,
              categoryAverages['writing'] ?? 0,
              const Color.fromARGB(255, 198, 124, 211),
              'Writing',
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (double value, TitleMeta meta) {
                  switch (value.toInt()) {
                    case 0:
                      return _buildAxisLabel('Read');
                    case 1:
                      return _buildAxisLabel('Speak');
                    case 2:
                      return _buildAxisLabel('Understand');
                    case 3:
                      return _buildAxisLabel('Write');
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 1),
              left: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              // tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String category = '';
                switch (groupIndex) {
                  case 0:
                    category = 'Read';
                    break;
                  case 1:
                    category = 'Speak';
                    break;
                  case 2:
                    category = 'Understand';
                    break;
                  case 3:
                    category = 'Write';
                    break;
                }
                return BarTooltipItem(
                  '$category\n${rod.toY.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create bar groups
  BarChartGroupData _createBarGroup(
    int x,
    double value,
    Color color,
    String label,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 22,
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  // Helper method to build axis labels
  Widget _buildAxisLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBoxPlotChart() {
    // Check if we have any data to display
    if (componentScores.isEmpty || _allListsEmpty(componentScores)) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No assessment data available for your students.'),
        ),
      );
    }

    // Calculate box plot statistics for each component
    Map<String, Map<String, double>> boxPlotStats = {};
    componentScores.forEach((component, scores) {
      if (scores.isNotEmpty) {
        boxPlotStats[component] = _calculateBoxPlotStats(scores);
      }
    });

    return Container(
      height: 320,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: CustomBoxPlotChart(boxPlotStats: boxPlotStats),
      ),
    );
  }

  Map<String, double> _calculateBoxPlotStats(List<double> scores) {
    // Sort the scores
    scores.sort();

    // Calculate statistics
    final min = scores.first;
    final max = scores.last;

    // Calculate median (Q2)
    final median =
        scores.length.isOdd
            ? scores[scores.length ~/ 2]
            : (scores[scores.length ~/ 2 - 1] + scores[scores.length ~/ 2]) / 2;

    // Calculate Q1 and Q3
    final q1Index = (scores.length * 0.25).round();
    final q1 = q1Index > 0 ? scores[q1Index - 1] : scores.first;

    final q3Index = (scores.length * 0.75).round();
    final q3 = q3Index > 0 ? scores[q3Index - 1] : scores.last;

    return {'min': min, 'q1': q1, 'median': median, 'q3': q3, 'max': max};
  }

  bool _allListsEmpty(Map<String, List<double>> map) {
    return map.values.every((list) => list.isEmpty);
  }

  Widget _buildScatterPlot() {
    if (componentScores.isEmpty ||
        componentScores['fluency']?.isEmpty == true ||
        componentScores['pronunciation']?.isEmpty == true) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No correlation data available.'),
        ),
      );
    }

    // Create scatter spots from component scores
    List<ScatterSpot> spots = [];
    final fluencyScores = componentScores['fluency']!;
    final pronunciationScores = componentScores['pronunciation']!;

    for (
      int i = 0;
      i < fluencyScores.length && i < pronunciationScores.length;
      i++
    ) {
      spots.add(
        ScatterSpot(
          fluencyScores[i],
          pronunciationScores[i],
          // radius: 8,
          // color: Colors.blue.withOpacity(0.6),
        ),
      );
    }

    return Container(
      height: 300,
      padding: EdgeInsets.only(top: 20, right: 20, bottom: 20),
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: spots,
          minX: 0,
          maxX: 100,
          minY: 0,
          maxY: 100,
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 1),
              left: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            verticalInterval: 20,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine:
                (value) => FlLine(color: Colors.black12, strokeWidth: 1),
            getDrawingVerticalLine:
                (value) => FlLine(color: Colors.black12, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  );
                },
              ),
              axisNameWidget: Text(
                'Fluency Score',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  );
                },
              ),
              axisNameWidget: RotatedBox(
                quarterTurns: -1,
                child: Text(
                  '',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          scatterTouchData: ScatterTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: ScatterTouchTooltipData(
              // tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
              tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItems: (touchedSpots) {
                // return touchedSpots.props((touchedSpot) {
                //   return ScatterTooltipItem(
                //     'Fluency: ${touchedSpot.spot.x.toStringAsFixed(1)}\nPronunciation: ${touchedSpot.spot.y.toStringAsFixed(1)}',
                //     textStyle: TextStyle(color: Colors.white),
                //   );
                // }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingTable() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Rankings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold),
                columns: [
                  DataColumn(
                    label: Text('Name'),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        sortColumn = 'name';
                        sortAscending = ascending;
                        _sortRankings();
                      });
                    },
                  ),
                  // Categories
                  DataColumn(
                    label: Text('Read'),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        sortColumn = 'reading';
                        sortAscending = ascending;
                        _sortRankings();
                      });
                    },
                  ),
                  DataColumn(
                    label: Text('Speak'),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        sortColumn = 'speaking';
                        sortAscending = ascending;
                        _sortRankings();
                      });
                    },
                  ),
                  DataColumn(
                    label: Text('Understand'),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        sortColumn = 'understanding';
                        sortAscending = ascending;
                        _sortRankings();
                      });
                    },
                  ),
                  DataColumn(
                    label: Text('Write'),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        sortColumn = 'writing';
                        sortAscending = ascending;
                        _sortRankings();
                      });
                    },
                  ),
                  DataColumn(
                    label: Text('Average'),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        sortColumn = 'average';
                        sortAscending = ascending;
                        _sortRankings();
                      });
                    },
                  ),
                ],
                rows: studentRankings.map((student) {
                  return DataRow(
                    cells: [
                      DataCell(Text(student['name'])),
                      DataCell(Text(student['reading'].toStringAsFixed(1))),
                      DataCell(Text(student['speaking'].toStringAsFixed(1))),
                      DataCell(Text(student['understanding'].toStringAsFixed(1))),
                      DataCell(Text(student['writing'].toStringAsFixed(1))),
                      DataCell(Text(student['average'].toStringAsFixed(1))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Box Plot Chart
class CustomBoxPlotChart extends StatelessWidget {
  final Map<String, Map<String, double>> boxPlotStats;

  CustomBoxPlotChart({required this.boxPlotStats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children:
          boxPlotStats.entries.map((entry) {
            final component = entry.key;
            final stats = entry.value;

            return Container(
              width: 120,
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Expanded(
                    child: CustomPaint(
                      size: Size(80, 240),
                      painter: BoxPlotPainter(
                        min: stats['min']!,
                        max: stats['max']!,
                        q1: stats['q1']!,
                        median: stats['median']!,
                        q3: stats['q3']!,
                        maxValue: 100, // Assuming scores are out of 100
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatComponentName(component),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                  // Add some stats below
                  Text(
                    'Median: ${stats['median']!.toStringAsFixed(1)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  String _formatComponentName(String name) {
    // Convert camelCase to Title Case with spaces
    final formattedName = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );

    return formattedName[0].toUpperCase() + formattedName.substring(1);
  }
}

// Custom Painter for Box Plot
class BoxPlotPainter extends CustomPainter {
  final double min;
  final double max;
  final double q1;
  final double median;
  final double q3;
  final double maxValue;

  BoxPlotPainter({
    required this.min,
    required this.max,
    required this.q1,
    required this.median,
    required this.q3,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define painting styles
    final boxStrokePaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final boxFillPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final medianPaint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final whiskerPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    // Map values to y-coordinates (inverting because y grows downward)
    final double height = size.height;
    double mapValueToY(double value) => height * (1 - value / maxValue);

    final yMin = mapValueToY(min);
    final yMax = mapValueToY(max);
    final yQ1 = mapValueToY(q1);
    final yQ3 = mapValueToY(q3);
    final yMedian = mapValueToY(median);

    // Define positions
    final centerX = size.width / 2;
    final boxWidth = size.width * 0.6;
    final left = centerX - boxWidth / 2;
    final right = centerX + boxWidth / 2;
    final whiskerWidth = boxWidth * 0.8;

    // Draw vertical line from min to max (the "whiskers")
    canvas.drawLine(Offset(centerX, yMin), Offset(centerX, yQ1), whiskerPaint);
    canvas.drawLine(Offset(centerX, yQ3), Offset(centerX, yMax), whiskerPaint);

    // Draw horizontal lines at min and max
    canvas.drawLine(
      Offset(centerX - whiskerWidth / 2, yMin),
      Offset(centerX + whiskerWidth / 2, yMin),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(centerX - whiskerWidth / 2, yMax),
      Offset(centerX + whiskerWidth / 2, yMax),
      whiskerPaint,
    );

    // Draw the box (Q1 to Q3)
    final boxRect = Rect.fromPoints(Offset(left, yQ1), Offset(right, yQ3));
    canvas.drawRect(boxRect, boxFillPaint);
    canvas.drawRect(boxRect, boxStrokePaint);

    // Draw the median line
    canvas.drawLine(Offset(left, yMedian), Offset(right, yMedian), medianPaint);

    // Add value labels
    final textStyle = TextStyle(color: Colors.black87, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Max value label
    textPainter.text = TextSpan(text: max.toStringAsFixed(1), style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(right + 4, yMax - textPainter.height / 2));

    // Min value label
    textPainter.text = TextSpan(text: min.toStringAsFixed(1), style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(right + 4, yMin - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
