// lib/models/app_user.dart
// A person who can log in: Admin, Teacher or Principal/VP.

class AppUser {
  final int id;
  final String fullName;
  final String loginId; // fixed forever, e.g. sania@school.com
  final String role; // 'admin', 'teacher' or 'vp'
  final String? contactEmail; // real Gmail used to share credentials
  final bool mustChangePassword; // true after account creation / password reset

  // Only for teachers who are also a Class Teacher
  final int? classTeacherOfClassId;
  final String? classTeacherOfClassName;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.loginId,
    required this.role,
    this.contactEmail,
    this.mustChangePassword = false,
    this.classTeacherOfClassId,
    this.classTeacherOfClassName,
  });

  // Builds a user from the API's JSON (UserDto)
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        fullName: json['fullName'],
        loginId: json['loginId'],
        role: json['role'],
        contactEmail: json['contactEmail'],
        mustChangePassword: json['mustChangePassword'] ?? false,
        classTeacherOfClassId: json['classTeacherOfClassId'],
        classTeacherOfClassName: json['classTeacherOfClassName'],
      );

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isVp => role == 'vp';
  bool get isClassTeacher => classTeacherOfClassId != null;

  // Nice label for the UI
  String get roleLabel {
    if (isAdmin) return 'Admin';
    if (isVp) return 'Principal / VP';
    return isClassTeacher ? 'Teacher • Class Teacher' : 'Teacher';
  }
}
