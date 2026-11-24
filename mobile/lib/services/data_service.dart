// lib/services/data_service.dart
// The CONTRACT between the screens and the data.
// Screens only talk to this abstract class, never to HTTP directly.
//  - Milestone 1: MockDataService implemented it with fake in-memory data
//    (deleted in Milestone 7; still visible in git tag v1-mock-ui).
//  - Milestone 7: ApiDataService implements it with real HTTP calls.
// Each method matches one endpoint of the .NET API (shown in the comments).

import '../models/account.dart';
import '../models/app_user.dart';
import '../models/assignment.dart';
import '../models/class_tracker.dart';
import '../models/report_card.dart';
import '../models/school_class.dart';
import '../models/student.dart';

abstract class DataService {
  // The logged-in user (null = logged out)
  AppUser? get currentUser;

  // ---------- Auth ----------
  Future<AppUser> login(String loginId, String password); // POST /api/auth/login
  Future<void> changePassword(String currentPassword, String newPassword); // POST /api/auth/change-password
  Future<Credentials> register(NewAccountRequest request); // POST /api/auth/register (Admin)
  Future<Credentials> resetPassword(int userId); // POST /api/auth/reset-password/{userId} (Admin)
  void logout(); // forget the token (no API call needed)

  // ---------- Users ----------
  Future<List<AppUser>> getUsers(); // GET /api/users (Admin)

  // ---------- Classes ----------
  Future<SchoolOverview> getOverview(); // GET /api/classes (Admin, VP)
  Future<ClassTracker> getClassTracker(int classId); // GET /api/classes/{id}/tracker
  Future<void> setPublished(int classId, bool publish); // PUT /api/classes/{id}/publish
  Future<ClassStudents> getClassStudents(int classId); // GET /api/classes/{id}/students

  // ---------- Students ----------
  Future<Student> addStudent(int classId, String fullName, String rollNo); // POST /api/classes/{id}/students
  Future<void> deleteStudent(int studentId); // DELETE /api/students/{id}
  Future<ReportCard> getReportCard(int studentId); // GET /api/students/{id}/report-card

  // ---------- Marks ----------
  Future<List<TeacherAssignment>> getMyAssignments(); // GET /api/assignments/mine
  Future<AssignmentMarks> getAssignmentMarks(int assignmentId); // GET /api/assignments/{id}/marks
  Future<void> saveMarks(int assignmentId, Map<int, int?> marksByStudentId,
      {required bool submit}); // PUT /api/assignments/{id}/marks
}
