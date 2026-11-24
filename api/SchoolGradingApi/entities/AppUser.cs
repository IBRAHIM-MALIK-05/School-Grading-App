namespace SchoolGradingApi.entities
{
    // Table: users  (everyone who can log in: admin, teacher, vp)
    public class AppUser
    {
        public int Id { get; set; }

        public string FullName { get; set; } = "";

        // Fixed forever, e.g. "sania@school.com". Nobody can change it.
        public string LoginId { get; set; } = "";

        // Real Gmail used by the Admin to send login details (optional)
        public string? ContactEmail { get; set; }

        // BCrypt hash of the password - the real password is never stored
        public string PasswordHash { get; set; } = "";

        // "admin", "teacher" or "vp"
        public string Role { get; set; } = "";

        // true = temporary password, must change it at next login
        public bool MustChangePassword { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
