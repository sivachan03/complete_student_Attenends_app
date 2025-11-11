import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addStudent(Student s) async {
    await _db.collection('students').doc(s.id).set(s.toMap());
  }

  Future<String> addStudentAutoId(Student s) async {
    final doc = await _db.collection('students').add(s.toMap());
    return doc.id;
  }

  Future<List<Student>> getAllStudents() async {
    final snap = await _db.collection('students').orderBy('roll_number').get();
    return snap.docs.map((d) => Student.fromMap(d.id, d.data())).toList();
  }

  Future<void> recordAbsence(String rollNumber, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // 🔹 Step 1: Find student by roll_number (not by doc ID)
    final query = await _db
        .collection("students")
        .where('roll_number', isEqualTo: rollNumber)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Student not found for roll number $rollNumber');
    }

    final studentData = query.docs.first.data();
    final studentId = query.docs.first.id;
    final studentName = studentData['student_name'];

    // 🔹 Step 2: Check if already marked absent for this day
    final existing = await _db
        .collection('absences')
        .where('student_id', isEqualTo: studentId)
        .get();

    // Filter by date in code to avoid composite index requirement
    final existingForDate = existing.docs.where((doc) {
      final data = doc.data();
      final absenceDate = (data['date_time'] as Timestamp).toDate();
      return absenceDate.year == startOfDay.year &&
          absenceDate.month == startOfDay.month &&
          absenceDate.day == startOfDay.day;
    }).toList();

    if (existingForDate.isNotEmpty) {
      print('⚠️ Already marked absent for this student today');
      return; // Stop here — no duplicate absence
    }

    // 🔹 Step 3: Add absence record
    await _db.collection('absences').add({
      'student_name': studentName,
      'roll_number': rollNumber,
      'student_id': studentId,
      'date_time': Timestamp.fromDate(startOfDay),
    });

    print('✅ Absence recorded for $studentName ($rollNumber)');
  }

  Future<Student?> getStudentByRollNumber(String rollNumber) async {
    final doc = await _db.collection('students').doc(rollNumber).get();
    if (doc.exists) {
      return Student.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // ✅ Fetch absentees as List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> getAbsenteesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _db
        .collection('absences')
        .where('date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date_time', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Include document ID
      return data;
    }).toList();
  }

  Future<void> deleteAbsence(String absenceId) async {
    await _db.collection('absences').doc(absenceId).delete();
  }

  /// ✅ Get students who were present every day in a date range
  Future<List<Student>> getStudentsPresentEveryDay(
    DateTime from,
    DateTime to,
  ) async {
    final allStudents = await getAllStudents();
    final absences = await getAbsencesBetween(from, to);

    final absentMap = <String, int>{};
    for (var a in absences) {
      final id = a['student_id'];
      absentMap[id] = (absentMap[id] ?? 0) + 1;
    }

    final totalDays = to.difference(from).inDays + 1;

    return allStudents
        .where((s) => (absentMap[s.id] ?? 0) == 0) // never absent
        .toList();
  }

  // Future<List<Map<String, dynamic>>> getAbsencesBetween(
  //   DateTime from,
  //   DateTime to,
  // ) async {
  //   List<Map<String, dynamic>> allAbsences = [];
  //   DateTime current = DateTime(from.year, from.month, from.day);
  //   final end = DateTime(to.year, to.month, to.day);

  //   while (!current.isAfter(end)) {
  //     final daily = await getAbsenteesForDate(current);
  //     allAbsences.addAll(daily);
  //     current = current.add(const Duration(days: 1));
  //   }

  //   return allAbsences;
  // }
  Future<List<Map<String, dynamic>>> getAbsencesBetween(
    DateTime from,
    DateTime to,
  ) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    final snap = await _db
        .collection('absences')
        .where('date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date_time', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Student>> getStudentsAbsentEveryDay(
    DateTime from,
    DateTime to,
  ) async {
    final allStudents = await getAllStudents();
    final absences = await getAbsencesBetween(from, to);

    final absentMap = <String, int>{}; // student_id -> absent days
    for (var a in absences) {
      final id = a['student_id'];
      absentMap[id] = (absentMap[id] ?? 0) + 1;
    }

    final totalDays =
        to.difference(from).inDays + 1; // total number of days in range

    return allStudents
        .where((s) => (absentMap[s.id] ?? 0) == totalDays)
        .toList();
  }

  Future<void> deleteAbsenceByStudentAndDate(
    String studentId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);

    final snap = await _db
        .collection('absences')
        .where('student_id', isEqualTo: studentId)
        .where('date_time', isEqualTo: Timestamp.fromDate(start))
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
