class Student {
  final String id; // Firestore doc id
  final String studentName;
  final String rollNumber;
  final String courseName;

  Student({
    required this.id,
    required this.studentName,
    required this.rollNumber,
    required this.courseName,
  });

  Map<String, dynamic> toMap() => {
    'student_name': studentName,
    'roll_number': rollNumber,
    'course_name': courseName,
  };

  factory Student.fromMap(String id, Map<String, dynamic> map) {
    return Student(
      id: id,
      studentName: map['student_name'] ?? '',
      rollNumber: map['roll_number'] ?? '',
      courseName: map['course_name'] ?? '',
    );
  }
}
