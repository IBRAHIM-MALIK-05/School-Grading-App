// lib/services/data_service.dart
// The CONTRACT between the screens and the data.
// Screens only talk to this abstract class, never to HTTP directly.
//  - Milestone 1: MockDataService implemented it with fake in-memory data
//    (deleted in Milestone 7; still visible in git tag v1-mock-ui).
//  - Milestone 7: ApiDataService implements it with real HTTP calls.
// Each method matches one endpoint of the .NET API (shown in the comments).

import '../models/account.dart';
import '../models/app_notification.dart';
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
  // portal: 'staff' (Teacher / VP Login) or 'admin' (Login as Admin); the API refuses the wrong one
  Future<AppUser> login(String loginId, String password, {String? portal}); // POST /api/auth/login
  Future<void> changePassword(String currentPassword, String newPassword); // POST /api/auth/change-password
  Future<Credentials> register(NewAccountRequest request); // POST /api/auth/register (Admin)
  Future<Credentials> resetPassword(int userId); // POST /api/auth/reset-password/{userId} (Admin)
  void logout(); // forget the token (no API call needed)

  // ---------- Users ----------
  Future<List<AppUser>> getUsers(); // GET /api/users (Admin)
  Future<AppUser> updateUser(int userId, EditUserRequest request); // PUT /api/users/{id} (Admin)

  // ---------- Classes ----------
  Future<SchoolOverview> getOverview(); // GET /api/classes (Admin, VP)
  Future<ClassTracker> getClassTracker(int classId); // GET /api/classes/{id}/tracker
  Future<void> setPublished(int classId, bool publish); // PUT /api/classes/{id}/publish
  Future<ClassStudents> getClassStudents(int classId); // GET /api/classes/{id}/students
  Future<List<SubjectInfo>> getSubjects(); // GET /api/subjects (Admin)
  Future<SubjectInfo> createSubject(String name, int maxMarks); // POST /api/subjects (Admin)
  Future<SubjectInfo> updateSubject(int subjectId, String name, int maxMarks); // PUT /api/subjects/{id} (Admin)
  Future<String> deleteSubject(int subjectId); // DELETE /api/subjects/{id} (Admin)
  // Soft delete only (isDeleted = true): the row stays in MySQL. Hard delete is a
  // backend-maintainer endpoint in Swagger and is deliberately NOT part of the app.
  Future<String> softDeleteUser(int userId); // DELETE /api/users/SoftDeleteById?id= (Admin)
  Future<String> softDeleteClass(int classId); // DELETE /api/classes/SoftDeleteById?id= (Admin)
  Future<SchoolClass> createClass(String gradeName, String section,
      ClassTeachersRequest teachers); // POST /api/classes (Admin)
  Future<SchoolClass> updateClassTeachers(
      int classId, ClassTeachersRequest teachers); // PUT /api/classes/{id}/assignments (Admin)
  Future<SchoolClass> editClass(int classId, String gradeName, String section,
      ClassTeachersRequest teachers); // PUT /api/classes/{id} (Admin: name + all teachers)

  // ---------- Students ----------
  Future<Student> addStudent(int classId, String fullName, String rollNo); // POST /api/classes/{id}/students
  // Returns the server's message, e.g. "Ali was deleted from Class 8 - B by the Class Teacher ..."
  Future<String> deleteStudent(int studentId); // DELETE /api/students/{id}
  Future<ReportCard> getReportCard(int studentId); // GET /api/students/{id}/report-card

  // ---------- Marks ----------
  Future<List<TeacherAssignment>> getMyAssignments(); // GET /api/assignments/mine
  Future<AssignmentMarks> getAssignmentMarks(int assignmentId); // GET /api/assignments/{id}/marks
  Future<void> saveMarks(int assignmentId, Map<int, int?> marksByStudentId,
      {required bool submit}); // PUT /api/assignments/{id}/marks

  // ---------- Result Date + Notification Bell (our own backend, no Firebase) ----------
  Future<ResultDateInfo> getResultDate(); // GET /api/settings/result-date (everyone)
  Future<ResultDateInfo> setResultDate(DateTime? day); // PUT /api/settings/result-date (VP only; null = clear)
  Future<NotificationInbox> getNotifications(); // GET /api/notifications (+ automatic deadline check)
  // Returns the server's message, e.g. "Reminder sent to Teacher Usman for Physics."
  Future<String> sendReminder(int assignmentId, String? note); // POST /api/notifications/remind (Class Teacher)
  Future<void> markNotificationRead(int notificationId); // PUT /api/notifications/{id}/read
  Future<void> markAllNotificationsRead(); // PUT /api/notifications/read-all
}
