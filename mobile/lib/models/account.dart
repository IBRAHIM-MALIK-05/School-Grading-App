// lib/models/account.dart
// Used by the Admin when creating accounts and resetting passwords.

// What the Admin fills in on the "Create Account" form.
class NewAccountRequest {
  final String fullName;
  final String role; // 'teacher' or 'vp'
  final String contactEmail; // the user's Gmail
  final int? classTeacherOfClassId; // optional: make them Class Teacher
  final List<SubjectClassPair> assignments; // e.g. Mathematics -> Class 8 - A

  const NewAccountRequest({
    required this.fullName,
    required this.role,
    required this.contactEmail,
    this.classTeacherOfClassId,
    this.assignments = const [],
  });

  // The JSON body sent to POST /api/auth/register (AddUserDto)
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'role': role,
        'contactEmail': contactEmail,
        'classTeacherOfClassId': classTeacherOfClassId,
        'assignments': [for (final a in assignments) a.toJson()],
      };
}

// One subject in one class that a teacher teaches, e.g. Mathematics -> Class 8 - A.
class SubjectClassPair {
  final int subjectId;
  final int classId;

  const SubjectClassPair(this.subjectId, this.classId);

  Map<String, dynamic> toJson() => {'subjectId': subjectId, 'classId': classId};

  @override
  bool operator ==(Object other) =>
      other is SubjectClassPair && other.subjectId == subjectId && other.classId == classId;

  @override
  int get hashCode => Object.hash(subjectId, classId);
}

// What the Admin sends to edit a Teacher / VP (PUT /api/users/{id}). The Login ID never changes.
class EditUserRequest {
  final String fullName;
  final String contactEmail;
  final int? classTeacherOfClassId; // null = not a Class Teacher
  final List<SubjectClassPair> assignments; // the COMPLETE list after saving

  const EditUserRequest({
    required this.fullName,
    required this.contactEmail,
    this.classTeacherOfClassId,
    this.assignments = const [],
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'contactEmail': contactEmail,
        'classTeacherOfClassId': classTeacherOfClassId,
        'assignments': [for (final a in assignments) a.toJson()],
      };
}

// What the server gives back: shown ONCE to the Admin to share.
class Credentials {
  final String fullName;
  final String loginId;
  final String temporaryPassword;
  final String? contactEmail;

  const Credentials({
    required this.fullName,
    required this.loginId,
    required this.temporaryPassword,
    this.contactEmail,
  });

  // From the API's CredentialsDto
  factory Credentials.fromJson(Map<String, dynamic> json) => Credentials(
        fullName: json['fullName'],
        loginId: json['loginId'],
        temporaryPassword: json['temporaryPassword'],
        contactEmail: json['contactEmail'],
      );
}
