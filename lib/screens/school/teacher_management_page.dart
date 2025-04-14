import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:literacy_check/screens/school/register_teacher.dart';
import 'teacher_details_page.dart'; // You'll create this

class TeacherManagementPage extends StatefulWidget {
  @override
  _TeacherManagementPageState createState() => _TeacherManagementPageState();
}

enum TeacherFilter { all, registered, notRegistered }

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  String? currSchoolId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, String>> unregisteredTeachers = [];
  TeacherFilter currentFilter = TeacherFilter.all;

  final ScrollController _scrollController = ScrollController();

  List<String> teacherIds = [];
  List<DocumentSnapshot> loadedTeachers = [];
  bool isLoading = false;
  int currentBatch = 0;
  static const int batchSize = 10;
  String searchQuery = '';
  bool _isInitializing = true; // Add this field

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoading) {
        _loadMoreTeachers();
      }
    });
  }

  Future<void> _fetchTeacherNamesFromUsers() async {
    if (currSchoolId == null) {
      print('School ID is null. Cannot fetch teacher names.');
      return;
    }

    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .where('schoolId', isEqualTo: currSchoolId)
              .where('role', isEqualTo: 'teacher')
              .get();

      setState(() {
        unregisteredTeachers =
            snapshot.docs.map((doc) {
              return {
                'name': doc['name'].toString(),
                'email': doc['email'].toString(),
                'id': doc.id,
              };
            }).toList();
      });
    } catch (e) {
      print('Error fetching teacher names: $e');
    }
  }

  Future<void> _loadSchoolId() async {
    String? id = await getSchoolId();
    setState(() {
      currSchoolId = id;
    });
  }

  Future<String?> getSchoolId() async {
    if (currentUser != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schools')
              .where('email', isEqualTo: currentUser!.email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('schoolId');
      }
    }
    return null;
  }

  Future<void> _initializeData() async {
    try {
      await _loadSchoolId();
      await _fetchTeacherNamesFromUsers();
      if (mounted) {
        await _loadTeacherIds();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadTeacherIds() async {
    if (currSchoolId == null) {
      print('School ID is null');
      return;
    }

    try {
      DocumentSnapshot schoolDoc =
          await _firestore.collection('schools').doc(currSchoolId).get();

      if (!schoolDoc.exists) {
        if (!mounted) return;
        setState(() {
          teacherIds = [];
          loadedTeachers.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('School record not found in the database')),
        );
        return;
      }

      if (!mounted) return;
      List<dynamic> ids = schoolDoc.get('teacherIds') ?? [];
      setState(() {
        teacherIds = ids.map((id) => id.toString()).toList();
        currentBatch = 0;
        loadedTeachers.clear();
      });

      // Load all teachers after setting teacherIds
      await _loadMoreTeachers();
    } catch (e) {
      print('Error loading teacher IDs: $e');
    }
  }

  Future<void> _loadMoreTeachers() async {
    setState(() => isLoading = true);
    try {
      // Load all teachers with matching schoolId instead of only those in teacherIds
      QuerySnapshot teacherSnapshot =
          await _firestore
              .collection('teachers')
              .where('schoolId', isEqualTo: currSchoolId)
              .get();

      if (!mounted) return;

      setState(() {
        loadedTeachers = teacherSnapshot.docs;
        isLoading = false;
      });

      print('Loaded ${loadedTeachers.length} total teachers');
      print('Registered teachers: ${teacherIds.length}');
      print(
        'Non-registered teachers: ${loadedTeachers.length - teacherIds.length}',
      );
    } catch (e) {
      print('Error loading teachers: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading teachers: $e')));
      }
    }
  }

  // Also add this debug method to help troubleshoot:
  void _debugPrintTeacherIds() {
    print('Current School ID: $currSchoolId');
    print('Teacher IDs: $teacherIds');
    print('Loaded Teachers: ${loadedTeachers.length}');
  }

  Future<int> _getStudentCount(String teacherId) async {
    QuerySnapshot snapshot =
        await _firestore
            .collection('students')
            .where('teacherId', isEqualTo: teacherId)
            .get();
    return snapshot.docs.length;
  }

  Future<void> _deleteTeacher(String teacherId) async {
    QuerySnapshot students =
        await _firestore
            .collection('students')
            .where('teacherId', isEqualTo: teacherId)
            .get();

    for (var student in students.docs) {
      await _firestore.collection('students').doc(student.id).delete();
    }

    await _firestore.collection('teachers').doc(teacherId).delete();
    await _firestore.collection('schools').doc(currSchoolId).update({
      'teacherIds': FieldValue.arrayRemove([teacherId]),
    });

    setState(() {
      teacherIds.remove(teacherId);
      loadedTeachers.removeWhere((doc) => doc.id == teacherId);
    });
  }

  Widget _buildTeacherCard(dynamic teacher) {
    bool isDocumentSnapshot = teacher is DocumentSnapshot;

    String name = isDocumentSnapshot ? teacher['name'] : teacher['name'];
    String email = isDocumentSnapshot ? teacher['email'] : teacher['email'];
    String teacherId = isDocumentSnapshot ? teacher.id : teacher['id'];
    bool isRegistered = teacherIds.contains(teacherId);

    return FutureBuilder<int>(
      future: _getStudentCount(teacherId),
      builder: (context, snapshot) {
        int studentCount = snapshot.data ?? 0;

        return GestureDetector(
          onTap: () {
            if (isRegistered) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => TeacherDetailsPage(
                        teacherDoc: isDocumentSnapshot ? teacher : null,
                        teacherData: isDocumentSnapshot ? null : teacher,
                        studentCount: studentCount,
                        isRegistered: isRegistered,
                      ),
                ),
              );
            }
          },
          onLongPress:
              isRegistered
                  ? () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Delete Teacher?'),
                            content: Text(
                              'This will delete all students under this teacher.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) await _deleteTeacher(teacherId);
                  }
                  : null,
          child: Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(
                Icons.person,
                color: isRegistered ? Colors.blue : Colors.grey,
              ),
              title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: $email'),
                  if (isRegistered) Text('Students: $studentCount'),
                  Text(
                    isRegistered ? 'Registered' : 'Not Registered',
                    style: TextStyle(
                      color: isRegistered ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                isRegistered ? Icons.check_circle : Icons.hourglass_empty,
                color: isRegistered ? Colors.green : Colors.orange,
                size: 24,
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }

  List<dynamic> get filteredTeachers {
  // First get all registered teachers and their emails
  final registered = loadedTeachers.where((doc) => teacherIds.contains(doc.id)).toList();
  final registeredEmails = registered.map((doc) => doc['email'].toString()).toSet();

  // Filter out unregistered teachers that have matching emails
  final uniqueUnregistered = unregisteredTeachers
      .where((teacher) =>
          !teacherIds.contains(teacher['id']) &&
          !registeredEmails.contains(teacher['email']))
      .toList();

  // Apply search filter if query exists
  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    
    final filteredRegistered = registered.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      final email = doc['email'].toString().toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    final filteredUnregistered = uniqueUnregistered.where((teacher) {
      final name = teacher['name'].toString().toLowerCase();
      final email = teacher['email'].toString().toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    // Return filtered results based on current filter
    switch (currentFilter) {
      case TeacherFilter.registered:
        return filteredRegistered;
      case TeacherFilter.notRegistered:
        return filteredUnregistered;
      case TeacherFilter.all:
      default:
        return [...filteredRegistered, ...filteredUnregistered];
    }
  }

  // If no search query, return based on registration filter
  switch (currentFilter) {
    case TeacherFilter.registered:
      return registered;
    case TeacherFilter.notRegistered:
      return uniqueUnregistered;
    case TeacherFilter.all:
    default:
      return [...registered, ...uniqueUnregistered];
  }
}

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Teacher Management'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading teachers...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTeacherIds,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Register Teacher',
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RegisterTeacher()),
            ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search teacher by name or email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          // Add filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All'),
                  selected: currentFilter == TeacherFilter.all,
                  onSelected: (selected) {
                    setState(() => currentFilter = TeacherFilter.all);
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Registered'),
                  selected: currentFilter == TeacherFilter.registered,
                  onSelected: (selected) {
                    setState(() => currentFilter = TeacherFilter.registered);
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Not Registered'),
                  selected: currentFilter == TeacherFilter.notRegistered,
                  onSelected: (selected) {
                    setState(() => currentFilter = TeacherFilter.notRegistered);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child:
                filteredTeachers.isEmpty
                    ? Center(
                      child: Text(
                        currentFilter == TeacherFilter.notRegistered
                            ? 'No pending teachers found.'
                            : currentFilter == TeacherFilter.registered
                            ? 'No registered teachers found.'
                            : 'No teachers found.',
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredTeachers.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<int>(
                          future: _getStudentCount(
                            filteredTeachers[index] is DocumentSnapshot
                                ? filteredTeachers[index].id
                                : filteredTeachers[index]['id'],
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                                  title: Container(
                                    width: 200,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 150,
                                        height: 16,
                                        margin: EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      Container(
                                        width: 100,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            }
                            return _buildTeacherCard(filteredTeachers[index]);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
