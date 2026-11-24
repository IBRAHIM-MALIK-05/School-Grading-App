namespace SchoolGradingApi.Dtos
{
    // POST /api/auth/login  (request)
    public class LoginDto
    {
        public string LoginId { get; set; } = "";
        public string Password { get; set; } = "";
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
        public List<int> AssignmentIds { get; set; } = new List<int>();   // subjects to teach (optional)
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
