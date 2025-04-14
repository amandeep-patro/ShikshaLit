class IdService {
  static String generateSchoolId() {
    return 'SCH${DateTime.now().millisecondsSinceEpoch}';
  }

  static String generateTeacherId() {
    return 'TCH${DateTime.now().millisecondsSinceEpoch}';
  }

  static String generateStudentId() {
    return 'STD${DateTime.now().millisecondsSinceEpoch}';
  }
}