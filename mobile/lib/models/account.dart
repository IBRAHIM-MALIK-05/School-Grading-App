// lib/models/account.dart
// Used by the Admin when creating accounts and resetting passwords.

// What the Admin fills in on the "Create Account" form.
class NewAccountRequest {
  final String fullName;
  final String role; // 'teacher' or 'vp'
  final String contactEmail; // the user's Gmail
  final int? classTeacherOfClassId; // optional: make them Class Teacher
  final List<int> assignmentIds; // subjects/classes they will teach

  const NewAccountRequest({
    required this.fullName,
    required this.role,
    required this.contactEmail,
    this.classTeacherOfClassId,
    this.assignmentIds = const [],
  });

  // The JSON body sent to POST /api/auth/register (AddUserDto)
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'role': role,
        'contactEmail': contactEmail,
        'classTeacherOfClassId': classTeacherOfClassId,
        'assignmentIds': assignmentIds,
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
