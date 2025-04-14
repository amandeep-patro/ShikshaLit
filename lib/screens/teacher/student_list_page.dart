import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:literacy_check/screens/teacher/student_details_page.dart';
import 'register_student.dart';

class StudentListPage extends StatefulWidget {
  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _students = [];
  List<DocumentSnapshot> _filteredStudents = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? currTeacherId;
  bool _isInitializing = true;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchStudents();
  }

  Future<void> _initializeData() async {
    try {
      await _loadTeacherId();
      if (mounted) {
        await _fetchStudents();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadTeacherId() async {
    String? id = await getTeacherId();
    setState(() {
      currTeacherId = id;
    });
  }

  Future<String?> getTeacherId() async {
    if (currentUser != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('teachers')
              .where('email', isEqualTo: currentUser!.email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('teacherId');
      }
    }
    return null;
  }

  Future<void> _fetchStudents() async {
    try {
      String teacherId = currTeacherId!;
      QuerySnapshot snapshot =
          await _firestore
              .collection('students')
              .where('teacherId', isEqualTo: teacherId)
              .get();

      setState(() {
        _students = snapshot.docs;
        _filteredStudents = _students;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching students: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      _filteredStudents =
          _students.where((student) {
            final name = student['name'].toLowerCase();
            return name.contains(query.toLowerCase());
          }).toList();
    });
  }

  Future<void> _deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
      setState(() {
        _students.removeWhere((student) => student.id == studentId);
        _filteredStudents.removeWhere((student) => student.id == studentId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Student deleted successfully')));
    } catch (e) {
      print('Error deleting student: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting student')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _fetchStudents();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterStudents,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),

      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredStudents.isEmpty
              ? Center(child: Text('No students found'))
              : ListView.builder(
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  return Card(
                    child: ListTile(
                      title: Text(student['name']),
                      subtitle: Text('Student ID: ${student['studentId']}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    StudentDetailsPage(student: student),
                          ),
                        );
                      },
                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('Delete Student'),
                                content: Text(
                                  'Are you sure you want to delete this student?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          await _deleteStudent(student.id);
                        }
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterStudent()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
