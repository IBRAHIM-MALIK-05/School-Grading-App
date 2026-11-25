// lib/services/api_data_service.dart
// Milestone 7: the REAL back-end.
// Every method sends an HTTP request to the ASP.NET Core Web API,
// which reads/writes the MySQL database.
//
//  - async/await: the app never freezes while waiting for the server
//  - JWT: after login we keep the token and send it in every request
//    as "Authorization: Bearer <token>"
//  - try/catch: network problems and API errors ({ "message": "..." })
//    become an AppException, so the screens show a clear message

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/account.dart';
import '../models/app_user.dart';
import '../models/assignment.dart';
import '../models/class_tracker.dart';
import '../models/json_helpers.dart';
import '../models/report_card.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import 'api_config.dart';
import 'app_exception.dart';
import 'data_service.dart';

class ApiDataService implements DataService {
  String? _token; // the JWT from POST /api/auth/login
  AppUser? _me;

  @override
  AppUser? get currentUser => _me;

  // ======================= HTTP helper =======================

  // Sends one request and returns the decoded JSON (or throws AppException).
  Future<dynamic> _request(String method, String path, {Object? body}) async {
    final url = Uri.parse('$apiBaseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    http.Response response;
    try {
      final request = http.Request(method, url)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      // ONE time limit for the whole exchange: sending AND reading the answer
      response = await _sendAndRead(request).timeout(apiTimeout);
    } on TimeoutException {
      throw AppException(0, 'The server is taking too long to answer. Please try again.');
    } on http.ClientException {
      // API not running, no internet, wrong address...
      throw AppException(0, 'Cannot connect to the server. Check your internet connection and try again.');
    }

    // The body is normally JSON, but a gateway error page (e.g. Azure 502/503 while
    // the free server is starting) is HTML -> do not crash, show a clear message.
    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      data = null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw AppException(response.statusCode, 'The server sent an unexpected answer. Please try again.');
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    if (data == null && response.statusCode >= 502 && response.statusCode <= 504) {
      throw AppException(response.statusCode,
          'The server is starting up or busy. Please wait a moment and try again.');
    }

    // Our API sends { "message": "..." }.
    // ASP.NET's own validation errors send { "title": "..." }.
    String message = 'Something went wrong (error ${response.statusCode}).';
    if (data is Map && data['message'] != null) {
      message = data['message'];
    } else if (data is Map && data['title'] != null) {
      message = data['title'];
    }
    if (response.statusCode == 401 && _token != null) {
      message = 'Your session has expired. Please log out and log in again.';
    }
    throw AppException(response.statusCode, message);
  }

  Future<http.Response> _sendAndRead(http.Request request) async {
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ======================= Auth =======================

  @override
  Future<AppUser> login(String loginId, String password) async {
    final data = await _request('POST', '/auth/login',
        body: {'loginId': loginId, 'password': password});
    _token = data['token'];
    _me = AppUser.fromJson(data['user']);
    return _me!;
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final data = await _request('POST', '/auth/change-password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword});
    _me = AppUser.fromJson(data); // mustChangePassword is now false
  }

  @override
  Future<Credentials> register(NewAccountRequest request) async {
    final data = await _request('POST', '/auth/register', body: request.toJson());
    return Credentials.fromJson(data);
  }

  @override
  Future<Credentials> resetPassword(int userId) async {
    final data = await _request('POST', '/auth/reset-password/$userId');
    return Credentials.fromJson(data);
  }

  @override
  void logout() {
    // A JWT cannot be "deleted" on the server; the app simply forgets it.
    _token = null;
    _me = null;
  }

  // ======================= Users =======================

  @override
  Future<List<AppUser>> getUsers() async {
    final data = await _request('GET', '/users');
    return listFromJson(data, AppUser.fromJson);
  }

  // ======================= Classes =======================

  @override
  Future<SchoolOverview> getOverview() async {
    final data = await _request('GET', '/classes');
    return SchoolOverview.fromJson(data);
  }

  @override
  Future<ClassTracker> getClassTracker(int classId) async {
    final data = await _request('GET', '/classes/$classId/tracker');
    return ClassTracker.fromJson(data);
  }

  @override
  Future<void> setPublished(int classId, bool publish) async {
    await _request('PUT', '/classes/$classId/publish', body: {'publish': publish});
  }

  @override
  Future<ClassStudents> getClassStudents(int classId) async {
    final data = await _request('GET', '/classes/$classId/students');
    return ClassStudents.fromJson(data);
  }

  // ======================= Students =======================

  @override
  Future<Student> addStudent(int classId, String fullName, String rollNo) async {
    final data = await _request('POST', '/classes/$classId/students',
        body: {'fullName': fullName, 'rollNo': rollNo});
    return Student.fromJson(data);
  }

  @override
  Future<List<SubjectInfo>> getSubjects() async {
    final data = await _request('GET', '/subjects');
    return listFromJson(data, SubjectInfo.fromJson);
  }

  @override
  Future<SchoolClass> createClass(
      String gradeName, String section, ClassTeachersRequest teachers) async {
    final data = await _request('POST', '/classes', body: {
      'gradeName': gradeName,
      'section': section,
      'classTeacherId': teachers.classTeacherId,
      'subjectTeachers': teachers.subjectTeachersJson,
    });
    return SchoolClass.fromJson(data);
  }

  @override
  Future<SchoolClass> updateClassTeachers(int classId, ClassTeachersRequest teachers) async {
    final data = await _request('PUT', '/classes/$classId/assignments', body: {
      'classTeacherId': teachers.classTeacherId,
      'subjectTeachers': teachers.subjectTeachersJson,
    });
    return SchoolClass.fromJson(data);
  }

  @override
  Future<String> deleteStudent(int studentId) async {
    final data = await _request('DELETE', '/students/$studentId');
    return (data is Map && data['message'] != null) ? data['message'] : 'Student deleted.';
  }

  @override
  Future<ReportCard> getReportCard(int studentId) async {
    final data = await _request('GET', '/students/$studentId/report-card');
    return ReportCard.fromJson(data);
  }

  // ======================= Marks =======================

  @override
  Future<List<TeacherAssignment>> getMyAssignments() async {
    final data = await _request('GET', '/assignments/mine');
    return listFromJson(data, TeacherAssignment.fromJson);
  }

  @override
  Future<AssignmentMarks> getAssignmentMarks(int assignmentId) async {
    final data = await _request('GET', '/assignments/$assignmentId/marks');
    return AssignmentMarks.fromJson(data);
  }

  @override
  Future<void> saveMarks(int assignmentId, Map<int, int?> marksByStudentId,
      {required bool submit}) async {
    final marks = marksByStudentId.entries
        .map((e) => {'studentId': e.key, 'obtained': e.value})
        .toList();
    await _request('PUT', '/assignments/$assignmentId/marks',
        body: {'marks': marks, 'submit': submit});
  }
}
