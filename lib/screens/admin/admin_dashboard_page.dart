import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'package:provider/single_child_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, double> regionPerformance = {};
  bool isLoading = true;
  List<Map<String, dynamic>> schoolRankings = [];
  bool showTopPerformers = true;
  Map<String, Map<String, double>> regionComponentScores = {};
  Map<String, List<double>> regionScoreDistributions = {};
  final List<String> components = [
    'reading',
    'speaking',
    'understanding',
    'writing',
    'activeListening',
    'fluency',
    'linguisticAbility',
    'phonologicalAwareness',
    'pronunciation',
    'visualUnderstanding',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadSchoolPerformanceData(),
      _loadSchoolRankings(),
      _loadRegionComponentData(),
      _loadRegionDistributions(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _loadSchoolPerformanceData() async {
    try {
      setState(() => isLoading = true);

      // Get all schools
      final schoolsSnapshot = await _firestore.collection('schools').get();
      Map<String, List<double>> regionScores = {};

      for (var schoolDoc in schoolsSnapshot.docs) {
        final schoolData = schoolDoc.data();
        final location = schoolData['location'] as String;
        final schoolId = schoolData['schoolId'] as String;

        // Get all students for this school
        final studentsSnapshot =
            await _firestore
                .collection('students')
                .where('schoolId', isEqualTo: schoolId)
                .get();

        double schoolTotalScore = 0;
        int studentCount = 0;

        // Calculate average performance for each student
        for (var studentDoc in studentsSnapshot.docs) {
          final resultDoc =
              await _firestore.collection('results').doc(studentDoc.id).get();

          if (resultDoc.exists) {
            final data = resultDoc.data()!;
            final categories = data['categories'] as Map<String, dynamic>;

            // Calculate average of all categories
            double studentScore =
                ((categories['reading'] ?? 0) +
                    (categories['speaking'] ?? 0) +
                    (categories['understanding'] ?? 0) +
                    (categories['writing'] ?? 0)) /
                4;

            schoolTotalScore += studentScore;
            studentCount++;
          }
        }

        if (studentCount > 0) {
          double schoolAverage = schoolTotalScore / studentCount;
          if (!regionScores.containsKey(location)) {
            regionScores[location] = [];
          }
          regionScores[location]!.add(schoolAverage);
        }
      }

      // Calculate average performance for each region
      regionScores.forEach((region, scores) {
        if (scores.isNotEmpty) {
          double sum = scores.reduce((a, b) => a + b);
          regionPerformance[region] = sum / scores.length;
        }
      });

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading school performance data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadSchoolRankings() async {
    try {
      final schoolsSnapshot = await _firestore.collection('schools').get();
      List<Map<String, dynamic>> rankings = [];

      for (var schoolDoc in schoolsSnapshot.docs) {
        final schoolData = schoolDoc.data();
        final schoolId = schoolData['schoolId'] as String;
        final location = schoolData['location'] as String;
        final name = schoolData['name'] as String;

        // Get all students for this school
        final studentsSnapshot =
            await _firestore
                .collection('students')
                .where('schoolId', isEqualTo: schoolId)
                .get();

        double totalScore = 0;
        int studentCount = 0;

        for (var studentDoc in studentsSnapshot.docs) {
          final resultDoc =
              await _firestore.collection('results').doc(studentDoc.id).get();

          if (resultDoc.exists) {
            final data = resultDoc.data()!;
            final categories = data['categories'] as Map<String, dynamic>;

            double studentScore =
                ((categories['reading'] ?? 0) +
                    (categories['speaking'] ?? 0) +
                    (categories['understanding'] ?? 0) +
                    (categories['writing'] ?? 0)) /
                4;

            totalScore += studentScore;
            studentCount++;
          }
        }

        if (studentCount > 0) {
          rankings.add({
            'name': name,
            'location': location,
            'score': totalScore / studentCount,
            'studentCount': studentCount,
          });
        }
      }

      setState(() {
        schoolRankings = rankings;
      });
    } catch (e) {
      print('Error loading school rankings: $e');
    }
  }

  Future<void> _loadRegionComponentData() async {
    try {
      final schoolsSnapshot = await _firestore.collection('schools').get();
      Map<String, Map<String, List<double>>> tempScores = {};

      for (var schoolDoc in schoolsSnapshot.docs) {
        final schoolData = schoolDoc.data();
        final location = schoolData['location'] as String;
        final schoolId = schoolData['schoolId'] as String;

        if (!tempScores.containsKey(location)) {
          tempScores[location] = Map.fromIterable(
            components,
            key: (e) => e as String,
            value: (_) => <double>[],
          );
        }

        final studentsSnapshot =
            await _firestore
                .collection('students')
                .where('schoolId', isEqualTo: schoolId)
                .get();

        for (var studentDoc in studentsSnapshot.docs) {
          final resultDoc =
              await _firestore.collection('results').doc(studentDoc.id).get();

          if (resultDoc.exists) {
            final data = resultDoc.data()!;
            final categories = data['categories'] as Map<String, dynamic>;
            final componentData = data['components'] as Map<String, dynamic>;

            // Add category scores
            tempScores[location]!['reading']!.add(
              categories['reading']?.toDouble() ?? 0,
            );
            tempScores[location]!['speaking']!.add(
              categories['speaking']?.toDouble() ?? 0,
            );
            tempScores[location]!['understanding']!.add(
              categories['understanding']?.toDouble() ?? 0,
            );
            tempScores[location]!['writing']!.add(
              categories['writing']?.toDouble() ?? 0,
            );

            // Add component scores
            tempScores[location]!['activeListening']!.add(
              componentData['activeListening']?.toDouble() ?? 0,
            );
            tempScores[location]!['fluency']!.add(
              componentData['fluency']?.toDouble() ?? 0,
            );
            tempScores[location]!['linguisticAbility']!.add(
              componentData['linguisticAbility']?.toDouble() ?? 0,
            );
            tempScores[location]!['phonologicalAwareness']!.add(
              componentData['phonologicalAwareness']?.toDouble() ?? 0,
            );
            tempScores[location]!['pronunciation']!.add(
              componentData['pronunciation']?.toDouble() ?? 0,
            );
            tempScores[location]!['visualUnderstanding']!.add(
              componentData['visualUnderstanding']?.toDouble() ?? 0,
            );
          }
        }
      }

      // Calculate averages
      Map<String, Map<String, double>> averages = {};
      tempScores.forEach((location, componentMap) {
        averages[location] = {};
        componentMap.forEach((component, scores) {
          if (scores.isNotEmpty) {
            averages[location]![component] =
                scores.reduce((a, b) => a + b) / scores.length;
          } else {
            averages[location]![component] = 0;
          }
        });
      });

      setState(() {
        regionComponentScores = averages;
      });
    } catch (e) {
      print('Error loading region component data: $e');
    }
  }

  Future<void> _loadRegionDistributions() async {
    try {
      final schoolsSnapshot = await _firestore.collection('schools').get();
      Map<String, List<double>> distributions = {};

      for (var schoolDoc in schoolsSnapshot.docs) {
        final schoolData = schoolDoc.data();
        final location = schoolData['location'] as String;
        final schoolId = schoolData['schoolId'] as String;

        if (!distributions.containsKey(location)) {
          distributions[location] = [];
        }

        final studentsSnapshot = await _firestore
            .collection('students')
            .where('schoolId', isEqualTo: schoolId)
            .get();

        for (var studentDoc in studentsSnapshot.docs) {
          final resultDoc = await _firestore
              .collection('results')
              .doc(studentDoc.id)
              .get();

          if (resultDoc.exists) {
            final data = resultDoc.data()!;
            final categories = data['categories'] as Map<String, dynamic>;
            
            double score = ((categories['reading'] ?? 0) +
                (categories['speaking'] ?? 0) +
                (categories['understanding'] ?? 0) +
                (categories['writing'] ?? 0)) /
                4;
            
            distributions[location]!.add(score);
          }
        }
      }

      setState(() {
        regionScoreDistributions = distributions;
      });
    } catch (e) {
      print('Error loading region distributions: $e');
    }
  }

  BoxPlotData _calculateBoxPlotData(List<double> scores) {
    if (scores.isEmpty) {
      return BoxPlotData(
        min: 0,
        q1: 0,
        median: 0,
        q3: 0,
        max: 0,
        outliers: [],
      );
    }

    scores.sort();
    
    double median;
    if (scores.length % 2 == 0) {
      median = (scores[scores.length ~/ 2 - 1] + scores[scores.length ~/ 2]) / 2;
    } else {
      median = scores[scores.length ~/ 2];
    }

    int q1Index = scores.length ~/ 4;
    int q3Index = (scores.length * 3) ~/ 4;
    
    double q1 = scores[q1Index];
    double q3 = scores[q3Index];
    double iqr = q3 - q1;
    
    double lowerFence = q1 - (1.5 * iqr);
    double upperFence = q3 + (1.5 * iqr);
    
    List<double> outliers = scores.where((score) => 
      score < lowerFence || score > upperFence).toList();
    
    double min = scores.where((score) => score >= lowerFence).reduce(math.min);
    double max = scores.where((score) => score <= upperFence).reduce(math.max);

    return BoxPlotData(
      min: min,
      q1: q1,
      median: median,
      q3: q3,
      max: max,
      outliers: outliers,
    );
  }

  Widget _buildPerformanceMap() {
    if (regionPerformance.isEmpty) {
      return Center(child: Text('No performance data available'));
    }

    // Sort regions by performance
    var sortedRegions =
        regionPerformance.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 400,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regional School Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: math.max(
                    MediaQuery.of(context).size.width - 32,
                    sortedRegions.length * 100.0,
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      minY: 0,
                      groupsSpace: 20,
                      barGroups: List.generate(
                        sortedRegions.length,
                        (index) => _createBarGroup(
                          index,
                          sortedRegions[index].value,
                          _getColorForPerformance(sortedRegions[index].value),
                          sortedRegions[index].key,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < sortedRegions.length) {
                                return Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    sortedRegions[value.toInt()].key,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return Text('');
                            },
                            reservedSize: 40,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 20,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

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

  Color _getColorForPerformance(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.blue;
    if (value >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Excellent (≥80)', Colors.green),
        SizedBox(width: 16),
        _buildLegendItem('Good (≥60)', Colors.blue),
        SizedBox(width: 16),
        _buildLegendItem('Fair (≥40)', Colors.orange),
        SizedBox(width: 16),
        _buildLegendItem('Poor (<40)', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRankedBarChart() {
    if (schoolRankings.isEmpty) {
      return Center(child: Text('No school ranking data available'));
    }

    // Sort schools by score
    schoolRankings.sort((a, b) => b['score'].compareTo(a['score']));

    // Take top/bottom 10 schools
    final displayedSchools =
        showTopPerformers
            ? schoolRankings.take(10).toList()
            : schoolRankings.reversed.take(10).toList();

    return Container(
      height: 400,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${showTopPerformers ? "Top" : "Bottom"} 10 Schools',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ToggleButtons(
                isSelected: [showTopPerformers, !showTopPerformers],
                onPressed: (index) {
                  setState(() {
                    showTopPerformers = index == 0;
                  });
                },
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Top'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Bottom'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: math.max(
                  MediaQuery.of(context).size.width - 32,
                  displayedSchools.length * 100.0,
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    minY: 0,
                    groupsSpace: 20,
                    barGroups: List.generate(
                      displayedSchools.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: displayedSchools[index]['score'],
                            color: _getColorForPerformance(
                              displayedSchools[index]['score'],
                            ),
                            width: 22,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < displayedSchools.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    displayedSchools[value.toInt()]['name'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }
                            return Text('');
                          },
                          reservedSize: 60,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 20,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    if (regionComponentScores.isEmpty) {
      return Center(child: Text('No heatmap data available'));
    }

    final regions = regionComponentScores.keys.toList();
    final shortNames = {
      'reading': 'Read',
      'speaking': 'Speak',
      'understanding': 'Understand',
      'writing': 'Write',
      'activeListening': 'Listen',
      'fluency': 'Fluency',
      'linguisticAbility': 'Lang',
      'phonologicalAwareness': 'Phono',
      'pronunciation': 'Pronun',
      'visualUnderstanding': 'Visual',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 400,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regional Component Performance Heatmap',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    dataTextStyle: TextStyle(fontSize: 12),
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    columns: [
                      DataColumn(label: Text('Region')),
                      ...components.map(
                        (component) => DataColumn(
                          label: RotatedBox(
                            quarterTurns: 3,
                            child: Text(shortNames[component] ?? component),
                          ),
                        ),
                      ),
                    ],
                    rows:
                        regions.map((region) {
                          return DataRow(
                            cells: [
                              DataCell(Text(region)),
                              ...components.map((component) {
                                final score =
                                    regionComponentScores[region]?[component] ??
                                    0;
                                return DataCell(
                                  Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _getHeatmapColor(score),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      score.toStringAsFixed(1),
                                      style: TextStyle(
                                        color:
                                            score > 50
                                                ? Colors.black
                                                : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildHeatmapLegend(),
          ],
        ),
      ),
    );
  }

  Color _getHeatmapColor(double value) {
    if (value >= 80) return Colors.green[400]!;
    if (value >= 60) return Colors.lime[400]!;
    if (value >= 40) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Excellent (≥80)', Colors.green[400]!),
        SizedBox(width: 16),
        _buildLegendItem('Good (≥60)', Colors.lime[400]!),
        SizedBox(width: 16),
        _buildLegendItem('Fair (≥40)', Colors.orange[400]!),
        SizedBox(width: 16),
        _buildLegendItem('Poor (<40)', Colors.red[400]!),
      ],
    );
  }

  Widget _buildBoxPlot() {
    if (regionScoreDistributions.isEmpty) {
      return Center(child: Text('No distribution data available'));
    }

    final regions = regionScoreDistributions.keys.toList();
    final boxPlots = regions.map((region) => 
      _calculateBoxPlotData(regionScoreDistributions[region]!)).toList();

    return Container(
      height: 400,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Distributions by Region',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: math.max(
                  MediaQuery.of(context).size.width - 32,
                  regions.length * 100.0,
                ),
                child: CustomPaint(
                  painter: BoxPlotPainter(
                    regions: regions,
                    boxPlots: boxPlots,
                    maxScore: 100,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildBoxPlotLegend(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.all(16),
                      child: _buildPerformanceMap(),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.all(16),
                      child: _buildHeatmap(),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.all(16),
                      child: _buildRankedBarChart(),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.all(16),
                      child: _buildBoxPlot(),
                    ),
                  ],
                ),
              ),
    );
  }
}

class BoxPlotData {
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final List<double> outliers;

  BoxPlotData({
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    required this.outliers,
  });
}

class BoxPlotPainter extends CustomPainter {
  final List<String> regions;
  final List<BoxPlotData> boxPlots;
  final double maxScore;

  BoxPlotPainter({
    required this.regions,
    required this.boxPlots,
    required this.maxScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blue;

    final boxWidth = 40.0;
    final leftPadding = 60.0; // Increased padding for score axis
    final bottomPadding = 40.0;
    final plotHeight = size.height - bottomPadding;
    final plotWidth = size.width - leftPadding;
    final spacing = plotWidth / (regions.length + 1);

    // Draw score axis first
    _drawScoreAxis(canvas, size, leftPadding, plotHeight);

    for (int i = 0; i < regions.length; i++) {
      final box = boxPlots[i];
      final centerX = leftPadding + (spacing * (i + 1));

      // Draw vertical line from min to max
      canvas.drawLine(
        Offset(centerX, _getY(box.min, plotHeight)),
        Offset(centerX, _getY(box.max, plotHeight)),
        paint,
      );

      // Draw box
      final boxRect = Rect.fromLTWH(
        centerX - boxWidth / 2,
        _getY(box.q3, plotHeight),
        boxWidth,
        _getY(box.q1, plotHeight) - _getY(box.q3, plotHeight),
      );
      canvas.drawRect(boxRect, paint);

      // Draw median line
      canvas.drawLine(
        Offset(centerX - boxWidth / 2, _getY(box.median, plotHeight)),
        Offset(centerX + boxWidth / 2, _getY(box.median, plotHeight)),
        paint..strokeWidth = 3,
      );

      // Draw whiskers
      paint.strokeWidth = 2;
      canvas.drawLine(
        Offset(centerX - boxWidth / 4, _getY(box.min, plotHeight)),
        Offset(centerX + boxWidth / 4, _getY(box.min, plotHeight)),
        paint,
      );
      canvas.drawLine(
        Offset(centerX - boxWidth / 4, _getY(box.max, plotHeight)),
        Offset(centerX + boxWidth / 4, _getY(box.max, plotHeight)),
        paint,
      );

      // Draw outliers
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.red;
      
      for (var outlier in box.outliers) {
        canvas.drawCircle(
          Offset(centerX, _getY(outlier, plotHeight)),
          3,
          dotPaint,
        );
      }

      // Draw region label
      _drawText(
        canvas,
        regions[i],
        Offset(centerX, size.height - bottomPadding + 10),
        align: TextAlign.center,
      );
    }
  }

  double _getY(double value, double height) {
    return height * (1 - (value / maxScore));
  }

  void _drawText(Canvas canvas, String text, Offset position, {TextAlign align = TextAlign.left}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black87,
        fontSize: 12,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    double dx = position.dx;
    if (align == TextAlign.center) {
      dx -= textPainter.width / 2;
    }

    textPainter.paint(
      canvas,
      Offset(dx, position.dy),
    );
  }

  void _drawScoreAxis(Canvas canvas, Size size, double leftPadding, double plotHeight) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey;

    // Draw axis line
    canvas.drawLine(
      Offset(leftPadding, 0),
      Offset(leftPadding, plotHeight),
      paint,
    );

    // Draw horizontal grid lines and score labels
    for (int score = 0; score <= 100; score += 20) {
      final y = _getY(score.toDouble(), plotHeight);
      
      // Draw grid line
      paint.color = Colors.grey.withOpacity(0.3);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        paint,
      );

      // Draw tick and label
      paint.color = Colors.grey;
      canvas.drawLine(
        Offset(leftPadding - 5, y),
        Offset(leftPadding, y),
        paint,
      );
      
      _drawText(
        canvas,
        score.toString(),
        Offset(leftPadding - 35, y - 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Widget _buildBoxPlotLegend() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
              ),
            ),
            SizedBox(width: 8),
            Text('Interquartile Range (Q1-Q3)'),
            SizedBox(width: 16),
            Container(
              width: 20,
              height: 2,
              color: Colors.blue,
            ),
            SizedBox(width: 8),
            Text('Min/Max Range'),
            SizedBox(width: 16),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            SizedBox(width: 8),
            Text('Outliers'),
          ],
        ),
      ],
    ),
  );
}

class SankeyPainter extends CustomPainter {
  final Map<String, Map<String, int>> transitions;
  final Map<String, Color> nodeColors;
  final List<String> levels;

  SankeyPainter({
    required this.transitions,
    required this.nodeColors,
    required this.levels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final nodeWidth = 60.0;
    final spacing = (size.width - nodeWidth * 2) / 3;
    final maxValue = _getMaxTransitionValue();

    // Draw nodes
    double y = 0;
    Map<String, Rect> leftNodes = {};
    Map<String, Rect> rightNodes = {};

    // Draw left nodes (Previous Level)
    for (var level in levels) {
      final height = _getSourceTotal(level) * size.height / maxValue;
      final rect = Rect.fromLTWH(0, y, nodeWidth, height);
      leftNodes[level] = rect;

      paint.color = nodeColors[level]!;
      canvas.drawRect(rect, paint);

      _drawText(canvas, level, rect);
      y += height + 4;
    }

    // Reset y for right nodes
    y = 0;
    // Draw right nodes (Current Level)
    for (var level in levels) {
      final height = _getTargetTotal(level) * size.height / maxValue;
      final rect = Rect.fromLTWH(size.width - nodeWidth, y, nodeWidth, height);
      rightNodes[level] = rect;

      paint.color = nodeColors[level]!;
      canvas.drawRect(rect, paint);

      _drawText(canvas, level, rect);
      y += height + 4;
    }

    // Draw flow lines
    for (var fromLevel in levels) {
      for (var toLevel in levels) {
        final value = transitions[fromLevel]![toLevel] ?? 0;
        if (value > 0) {
          final startRect = leftNodes[fromLevel]!;
          final endRect = rightNodes[toLevel]!;

          final path = Path();
          path.moveTo(startRect.right, startRect.center.dy);
          path.cubicTo(
            startRect.right + spacing,
            startRect.center.dy,
            endRect.left - spacing,
            endRect.center.dy,
            endRect.left,
            endRect.center.dy,
          );

          paint.color = nodeColors[fromLevel]!.withOpacity(0.3);
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = value * size.height / maxValue / 2;
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  void _drawText(Canvas canvas, String text, Rect rect) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  int _getMaxTransitionValue() {
    int max = 0;
    for (var from in transitions.values) {
      final total = from.values.reduce((a, b) => a + b);
      if (total > max) max = total;
    }
    return max;
  }

  int _getSourceTotal(String level) {
    return transitions[level]!.values.reduce((a, b) => a + b);
  }

  int _getTargetTotal(String level) {
    int total = 0;
    for (var from in transitions.values) {
      total += from[level] ?? 0;
    }
    return total;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
