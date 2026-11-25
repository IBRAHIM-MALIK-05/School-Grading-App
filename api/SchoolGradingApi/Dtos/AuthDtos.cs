namespace SchoolGradingApi.Dtos
{
    // POST /api/auth/login  (request)
    public class LoginDto
    {
        public string LoginId { get; set; } = "";
        public string Password { get; set; } = "";

        // Optional: which login screen was used. "admin" = Admin Login, "staff" = Teacher / VP Login.
        // Left out (null) = no check, so older clients and the Postman tests keep working.
        public string? Portal { get; set; }
    }

    // POST /api/auth/login  (response)
    public class LoginResponseDto
    {
        public string Token { get; set; } = "";       // JWT, send it as "Authorization: Bearer <token>"
        public DateTime ExpiresAt { get; set; }
        public UserDto User { get; set; } = new UserDto();
    }

    // A user as the app sees it (never contains the password hash)
    public class UserDto
    {
        public int Id { get; set; }
        public string FullName { get; set; } = "";
        public string LoginId { get; set; } = "";
        public string Role { get; set; } = "";
        public string? ContactEmail { get; set; }
        public bool MustChangePassword { get; set; }
        public int? ClassTeacherOfClassId { get; set; }
        public string? ClassTeacherOfClassName { get; set; }
    }

    // POST /api/auth/change-password
    public class ChangePasswordDto
    {
        public string CurrentPassword { get; set; } = "";
        public string NewPassword { get; set; } = "";
    }

    // POST /api/auth/register  (Admin creates an account)
    public class AddUserDto
    {
        public string FullName { get; set; } = "";
        public string Role { get; set; } = "";                 // "teacher" or "vp"
        public string ContactEmail { get; set; } = "";         // the user's Gmail
        public int? ClassTeacherOfClassId { get; set; }        // optional
        public List<int> AssignmentIds { get; set; } = new List<int>();   // existing class-subjects to take over (optional)
        public List<SubjectClassDto> Assignments { get; set; } = new List<SubjectClassDto>();   // "Mathematics -> Class 8 - A" (optional)
    }

    // One "subject in a class" this teacher will teach, e.g. Mathematics -> Class 8 - A.
    // If someone already teaches it there, it moves to this teacher (marks are kept);
    // if nobody teaches it there yet, the subject is added to that class.
    public class SubjectClassDto
    {
        public int SubjectId { get; set; }
        public int ClassId { get; set; }
    }

    // PUT /api/users/{id}  (Admin edits a Teacher or Principal/VP; the Login ID never changes)
    public class EditUserDto
    {
        public string FullName { get; set; } = "";
        public string ContactEmail { get; set; } = "";
        public int? ClassTeacherOfClassId { get; set; }        // teachers only; null = not a Class Teacher
        // Teachers only: the COMPLETE list of subjects + classes after saving.
        // A pair left out is taken away from this teacher - refused if it already has marks.
        public List<SubjectClassDto> Assignments { get; set; } = new List<SubjectClassDto>();
    }

    // Response of register / reset-password: shown ONCE to the Admin
    public class CredentialsDto
    {
        public string FullName { get; set; } = "";
        public string LoginId { get; set; } = "";
        public string TemporaryPassword { get; set; } = "";
        public string? ContactEmail { get; set; }
    }
}
