// lib/services/mock_data_service.dart
// Milestone 1: a FAKE back-end that lives in memory.
// It follows the SAME rules the real .NET API will follow later
// (who is allowed to do what, locked classes, password rules...),
// and throws AppException with the same HTTP status codes.
// A small delay is added so loading spinners can be seen.

import 'dart:math';

import '../mock_data/dummy_db.dart';
import '../models/account.dart';
import '../models/app_user.dart';
import '../models/assignment.dart';
import '../models/class_tracker.dart';
import '../models/report_card.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import 'app_exception.dart';
import 'data_service.dart';

class MockDataService implements DataService {
  // ---------- our in-memory "tables" (copied from DummyDB) ----------
  final List<DbUser> _users = DummyDB.users();
  final List<DbSubject> _subjects = DummyDB.subjects();
  final List<DbClass> _classes = DummyDB.classes();
  final List<DbStudent> _students = DummyDB.students();
  final List<DbAssignment> _assignments = DummyDB.assignments();
  late final List<DbMark> _marks = DummyDB.marks(_students, _assignments);

  DbUser? _me; // the logged-in user (plays the role of the JWT token)

  // Pretend network delay so spinners show
  Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: 600));

  int _nextId(Iterable<int> ids) => ids.isEmpty ? 1 : ids.reduce(max) + 1;

  // ======================= helpers =======================

  DbUser _requireLogin() {
    if (_me == null) throw AppException(401, 'Please log in first.');
    return _me!;
  }

  DbUser _requireRole(List<String> roles) {
    final me = _requireLogin();
    if (!roles.contains(me.role)) {
      throw AppException(403, 'You are not allowed to do this.');
    }
    return me;
  }

  DbClass _findClass(int classId) => _classes.firstWhere(
        (c) => c.id == classId,
        orElse: () => throw AppException(404, 'Class not found.'),
      );

  String _className(DbClass c) => '${c.gradeName} - ${c.section}';

  DbUser? _findUser(int? id) {
    for (final u in _users) {
      if (u.id == id) return u;
    }
    return null;
  }

  DbSubject _subject(int id) => _subjects.firstWhere((s) => s.id == id);

  List<DbStudent> _studentsOf(int classId) =>
      _students.where((s) => s.classId == classId).toList()
        ..sort((a, b) => a.rollNo.compareTo(b.rollNo));

  List<DbAssignment> _assignmentsOf(int classId) =>
      _assignments.where((a) => a.classId == classId).toList()
        ..sort((a, b) => a.subjectId.compareTo(b.subjectId));

  DbMark? _findMark(int studentId, int subjectId) {
    for (final m in _marks) {
      if (m.studentId == studentId && m.subjectId == subjectId) return m;
    }
    return null;
  }

  int _enteredCount(DbAssignment a) {
    final ids = _studentsOf(a.classId).map((s) => s.id).toSet();
    return _marks
        .where((m) => m.subjectId == a.subjectId && ids.contains(m.studentId))
        .length;
  }

  AppUser _toAppUser(DbUser u) {
    DbClass? myClass;
    for (final c in _classes) {
      if (c.classTeacherId == u.id) myClass = c;
    }
    return AppUser(
      id: u.id,
      fullName: u.fullName,
      loginId: u.loginId,
      role: u.role,
      contactEmail: u.contactEmail,
      mustChangePassword: u.mustChangePassword,
      classTeacherOfClassId: myClass?.id,
      classTeacherOfClassName: myClass == null ? null : _className(myClass),
    );
  }

  SchoolClass _toSchoolClass(DbClass c) {
    final teacher = _findUser(c.classTeacherId);
    return SchoolClass(
      id: c.id,
      gradeName: c.gradeName,
      section: c.section,
      classTeacherId: c.classTeacherId,
      classTeacherName: teacher?.fullName,
      studentCount: _studentsOf(c.id).length,
      isPublished: c.resultsPublishedAt != null,
      subjects: _assignmentsOf(c.id).map((a) {
        final subject = _subject(a.subjectId);
        return ClassSubject(
          assignmentId: a.id,
          subjectId: subject.id,
          subjectName: subject.name,
          maxMarks: subject.maxMarks,
          teacherId: a.teacherId,
          teacherName: _findUser(a.teacherId)?.fullName,
          isSubmitted: a.submittedAt != null,
        );
      }).toList(),
    );
  }

  Student _toStudent(DbStudent s) =>
      Student(id: s.id, fullName: s.fullName, rollNo: s.rollNo, classId: s.classId);

  TeacherAssignment _toTeacherAssignment(DbAssignment a) {
    final c = _findClass(a.classId);
    final subject = _subject(a.subjectId);
    return TeacherAssignment(
      id: a.id,
      classId: c.id,
      className: _className(c),
      subjectId: subject.id,
      subjectName: subject.name,
      maxMarks: subject.maxMarks,
      studentCount: _studentsOf(c.id).length,
      enteredCount: _enteredCount(a),
      submittedAt: a.submittedAt,
      isClassPublished: c.resultsPublishedAt != null,
    );
  }

  // Admin: any class. Teacher: classes they teach OR are class teacher of.
  void _checkCanManageStudents(DbUser me, DbClass c) {
    if (me.role == 'admin') return;
    final teachesHere = _assignments
        .any((a) => a.classId == c.id && a.teacherId == me.id);
    if (me.role == 'teacher' && (teachesHere || c.classTeacherId == me.id)) {
      return;
    }
    throw AppException(403, 'You can only manage students of your own classes.');
  }

  // Class teacher of THIS class, or Admin / VP.
  void _checkCanViewClassResults(DbUser me, DbClass c) {
    if (me.role == 'admin' || me.role == 'vp') return;
    if (c.classTeacherId == me.id) return;
    throw AppException(403, 'Only the Class Teacher of ${_className(c)} can view this.');
  }

  // Same rules the API will use for new passwords
  String? _passwordProblem(DbUser user, String newPassword) {
    if (newPassword.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(newPassword) ||
        !RegExp(r'[0-9]').hasMatch(newPassword)) {
      return 'Password must contain at least one letter and one number.';
    }
    if (newPassword.toLowerCase() == user.loginId.toLowerCase()) {
      return 'Password cannot be the same as your Login ID.';
    }
    if (newPassword == user.password) {
      return 'New password must be different from the current one.';
    }
    return null;
  }

  // "Teacher Ali Raza" -> "ali@school.com" (ali2@, ali3@ ... if taken)
  String _generateLoginId(String fullName) {
    const titles = {'teacher', 'mr', 'mrs', 'ms', 'miss', 'dr', 'sir', 'vp', 'principal'};
    final words = fullName
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^a-z]'), ''))
        .where((w) => w.isNotEmpty && !titles.contains(w))
        .toList();
    final base = words.isEmpty ? 'user' : words.first;
    var candidate = '$base@school.com';
    var n = 2;
    while (_users.any((u) => u.loginId == candidate)) {
      candidate = '$base$n@school.com';
      n++;
    }
    return candidate;
  }

  // 10 random characters; no look-alike characters (0/O, 1/l/I)
  String _generateTempPassword() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const all = letters + digits;
    final random = Random.secure();
    while (true) {
      final pwd = List.generate(10, (_) => all[random.nextInt(all.length)]).join();
      if (RegExp(r'[A-Za-z]').hasMatch(pwd) && RegExp(r'[0-9]').hasMatch(pwd)) {
        return pwd;
      }
    }
  }

  String _grade(double percentage) {
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  // ======================= Auth =======================

  @override
  AppUser? get currentUser => _me == null ? null : _toAppUser(_me!);

  @override
  Future<AppUser> login(String loginId, String password) async {
    await _delay();
    final id = loginId.trim().toLowerCase();
    DbUser? user;
    for (final u in _users) {
      if (u.loginId == id) user = u;
    }
    if (user == null || user.password != password) {
      throw AppException(401, 'Invalid Login ID or password.');
    }
    _me = user;
    return _toAppUser(user);
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _delay();
    final me = _requireLogin();
    if (me.password != currentPassword) {
      throw AppException(400, 'Current password is incorrect.');
    }
    final problem = _passwordProblem(me, newPassword);
    if (problem != null) throw AppException(400, problem);
    me.password = newPassword;
    me.mustChangePassword = false;
  }

  @override
  Future<Credentials> register(NewAccountRequest request) async {
    await _delay();
    _requireRole(['admin']);

    final name = request.fullName.trim();
    final email = request.contactEmail.trim();
    if (name.isEmpty) throw AppException(400, 'Full name is required.');
    if (request.role != 'teacher' && request.role != 'vp') {
      throw AppException(400, 'Role must be Teacher or Principal/VP.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw AppException(400, 'Please enter a valid email address.');
    }

    DbClass? classToLead;
    if (request.classTeacherOfClassId != null) {
      if (request.role != 'teacher') {
        throw AppException(400, 'Only a Teacher can be a Class Teacher.');
      }
      classToLead = _findClass(request.classTeacherOfClassId!);
      if (classToLead.classTeacherId != null) {
        throw AppException(409,
            '${_className(classToLead)} already has a Class Teacher.');
      }
    }
    if (request.role != 'teacher' && request.assignmentIds.isNotEmpty) {
      throw AppException(400, 'Only a Teacher can be given subjects.');
    }

    final tempPassword = _generateTempPassword();
    final user = DbUser(
      _nextId(_users.map((u) => u.id)),
      name,
      _generateLoginId(name),
      tempPassword,
      request.role,
      contactEmail: email,
      mustChangePassword: true, // must change on first login
    );
    _users.add(user);

    // Make them class teacher + give them subjects (replaces the old teacher)
    classToLead?.classTeacherId = user.id;
    for (final a in _assignments) {
      if (request.assignmentIds.contains(a.id)) a.teacherId = user.id;
    }

    return Credentials(
      fullName: user.fullName,
      loginId: user.loginId,
      temporaryPassword: tempPassword,
      contactEmail: user.contactEmail,
    );
  }

  @override
  Future<Credentials> resetPassword(int userId) async {
    await _delay();
    final me = _requireRole(['admin']);
    final user = _findUser(userId);
    if (user == null) throw AppException(404, 'User not found.');
    if (user.id == me.id) {
      throw AppException(400, 'Use Change Password for your own account.');
    }
    final tempPassword = _generateTempPassword();
    user.password = tempPassword;
    user.mustChangePassword = true;
    return Credentials(
      fullName: user.fullName,
      loginId: user.loginId,
      temporaryPassword: tempPassword,
      contactEmail: user.contactEmail,
    );
  }

  @override
  void logout() {
    _me = null;
  }

  // ======================= Users =======================

  @override
  Future<List<AppUser>> getUsers() async {
    await _delay();
    _requireRole(['admin']);
    return _users.map(_toAppUser).toList();
  }

  // ======================= Classes =======================

  @override
  Future<SchoolOverview> getOverview() async {
    await _delay();
    _requireRole(['admin', 'vp']);
    final classes = _classes.map(_toSchoolClass).toList();
    return SchoolOverview(
      sections: classes.length,
      students: _students.length,
      teachers: _users.where((u) => u.role == 'teacher').length,
      cardsReady: classes
          .where((c) => c.isPublished)
          .fold(0, (sum, c) => sum + c.studentCount),
      pendingSubjects: _assignments.where((a) => a.submittedAt == null).length,
      classes: classes,
    );
  }

  @override
  Future<ClassTracker> getClassTracker(int classId) async {
    await _delay();
    final me = _requireLogin();
    final c = _findClass(classId);
    _checkCanViewClassResults(me, c);
    final students = _studentsOf(classId);
    return ClassTracker(
      schoolClass: _toSchoolClass(c),
      students: students.map(_toStudent).toList(),
      subjects: _assignmentsOf(classId).map((a) {
        final subject = _subject(a.subjectId);
        return SubjectStatus(
          subjectName: subject.name,
          maxMarks: subject.maxMarks,
          teacherName: _findUser(a.teacherId)?.fullName ?? '—',
          enteredCount: _enteredCount(a),
          studentCount: students.length,
          submittedAt: a.submittedAt,
        );
      }).toList(),
    );
  }

  @override
  Future<void> setPublished(int classId, bool publish) async {
    await _delay();
    final me = _requireLogin();
    final c = _findClass(classId);
    if (c.classTeacherId != me.id) {
      throw AppException(403, 'Only the Class Teacher can publish results.');
    }
    if (publish) {
      final pending = _assignmentsOf(classId)
          .where((a) => a.submittedAt == null)
          .map((a) => _subject(a.subjectId).name)
          .toList();
      if (pending.isNotEmpty) {
        throw AppException(
            409, 'Cannot publish yet. Still waiting for: ${pending.join(', ')}.');
      }
      c.resultsPublishedAt = DateTime.now();
    } else {
      c.resultsPublishedAt = null;
    }
  }

  @override
  Future<ClassStudents> getClassStudents(int classId) async {
    await _delay();
    final me = _requireLogin();
    final c = _findClass(classId);
    _checkCanManageStudents(me, c);
    return ClassStudents(
      classId: c.id,
      className: _className(c),
      isPublished: c.resultsPublishedAt != null,
      students: _studentsOf(classId).map(_toStudent).toList(),
    );
  }

  // ======================= Students =======================

  @override
  Future<Student> addStudent(int classId, String fullName, String rollNo) async {
    await _delay();
    final me = _requireLogin();
    final c = _findClass(classId);
    _checkCanManageStudents(me, c);

    final name = fullName.trim();
    var roll = rollNo.trim();
    if (name.isEmpty || roll.isEmpty) {
      throw AppException(400, 'Name and roll number are required.');
    }
    if (int.tryParse(roll) != null) roll = roll.padLeft(2, '0'); // 7 -> "07"
    if (c.resultsPublishedAt != null) {
      throw AppException(409, 'Results of ${_className(c)} are published. Unpublish first.');
    }
    if (_students.any((s) => s.classId == classId && s.rollNo == roll)) {
      throw AppException(409, 'Roll number $roll already exists in ${_className(c)}.');
    }

    final student = DbStudent(_nextId(_students.map((s) => s.id)), name, roll, classId);
    _students.add(student);

    // A new student has no marks yet, so no subject of this class
    // can stay "submitted" -> tracker stays accurate.
    for (final a in _assignments.where((a) => a.classId == classId)) {
      a.submittedAt = null;
    }
    return _toStudent(student);
  }

  @override
  Future<void> deleteStudent(int studentId) async {
    await _delay();
    final me = _requireLogin();
    final student = _students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => throw AppException(404, 'Student not found.'),
    );
    final c = _findClass(student.classId);
    _checkCanManageStudents(me, c);
    if (c.resultsPublishedAt != null) {
      throw AppException(409, 'Results of ${_className(c)} are published. Unpublish first.');
    }
    _marks.removeWhere((m) => m.studentId == studentId); // like ON DELETE CASCADE
    _students.remove(student);
  }

  @override
  Future<ReportCard> getReportCard(int studentId) async {
    await _delay();
    final me = _requireLogin();
    final student = _students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => throw AppException(404, 'Student not found.'),
    );
    final c = _findClass(student.classId);
    _checkCanViewClassResults(me, c);

    final lines = _assignmentsOf(c.id).map((a) {
      final subject = _subject(a.subjectId);
      return ReportLine(
        subjectName: subject.name,
        maxMarks: subject.maxMarks,
        obtained: _findMark(student.id, subject.id)?.obtained,
      );
    }).toList();

    final totalMax = lines.fold(0, (sum, l) => sum + l.maxMarks);
    final totalObtained = lines.fold(0, (sum, l) => sum + (l.obtained ?? 0));
    final isComplete = lines.every((l) => l.obtained != null);
    final percentage = isComplete && totalMax > 0
        ? totalObtained * 100 / totalMax
        : null;

    return ReportCard(
      schoolName: DummyDB.schoolName,
      studentName: student.fullName,
      rollNo: student.rollNo,
      className: _className(c),
      classTeacherName: _findUser(c.classTeacherId)?.fullName,
      lines: lines,
      totalObtained: totalObtained,
      totalMax: totalMax,
      percentage: percentage,
      grade: percentage == null ? null : _grade(percentage),
      isComplete: isComplete,
      isPublished: c.resultsPublishedAt != null,
    );
  }

  // ======================= Marks =======================

  @override
  Future<List<TeacherAssignment>> getMyAssignments() async {
    await _delay();
    final me = _requireRole(['teacher']);
    final mine = _assignments.where((a) => a.teacherId == me.id).toList()
      ..sort((a, b) => a.subjectId != b.subjectId
          ? a.subjectId.compareTo(b.subjectId)
          : a.classId.compareTo(b.classId));
    return mine.map(_toTeacherAssignment).toList();
  }

  DbAssignment _myAssignment(DbUser me, int assignmentId) {
    final a = _assignments.firstWhere(
      (a) => a.id == assignmentId,
      orElse: () => throw AppException(404, 'Assignment not found.'),
    );
    if (a.teacherId != me.id) {
      throw AppException(403, 'This subject/class is not assigned to you.');
    }
    return a;
  }

  @override
  Future<AssignmentMarks> getAssignmentMarks(int assignmentId) async {
    await _delay();
    final me = _requireRole(['teacher']);
    final a = _myAssignment(me, assignmentId);
    return AssignmentMarks(
      assignment: _toTeacherAssignment(a),
      rows: _studentsOf(a.classId).map((s) {
        return MarkRow(
          studentId: s.id,
          studentName: s.fullName,
          rollNo: s.rollNo,
          obtained: _findMark(s.id, a.subjectId)?.obtained,
        );
      }).toList(),
    );
  }

  @override
  Future<void> saveMarks(int assignmentId, Map<int, int?> marksByStudentId,
      {required bool submit}) async {
    await _delay();
    final me = _requireRole(['teacher']);
    final a = _myAssignment(me, assignmentId);
    final c = _findClass(a.classId);
    final subject = _subject(a.subjectId);

    if (c.resultsPublishedAt != null) {
      throw AppException(409, 'Results of ${_className(c)} are published. Marks are locked.');
    }

    final classStudentIds = _studentsOf(c.id).map((s) => s.id).toSet();

    // 1) validate everything first
    for (final entry in marksByStudentId.entries) {
      if (!classStudentIds.contains(entry.key)) {
        throw AppException(400, 'Student ${entry.key} is not in ${_className(c)}.');
      }
      final value = entry.value;
      if (value != null && (value < 0 || value > subject.maxMarks)) {
        throw AppException(400, 'Marks must be between 0 and ${subject.maxMarks}.');
      }
    }

    // 2) save (insert / update / remove)
    marksByStudentId.forEach((studentId, value) {
      final existing = _findMark(studentId, subject.id);
      if (value == null) {
        if (existing != null) _marks.remove(existing);
      } else if (existing == null) {
        _marks.add(DbMark(_nextId(_marks.map((m) => m.id)), studentId,
            subject.id, value, me.id));
      } else {
        existing.obtained = value;
        existing.enteredBy = me.id;
      }
    });

    // 3) submitted or not?
    final complete = _enteredCount(a) == classStudentIds.length;
    if (submit) {
      if (!complete) {
        final missing = classStudentIds.length - _enteredCount(a);
        throw AppException(400,
            'Marks saved, but cannot submit: $missing student(s) still have no marks.');
      }
      a.submittedAt = DateTime.now();
    } else if (!complete) {
      a.submittedAt = null; // a removed mark makes it incomplete again
    }
  }
}
