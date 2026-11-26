namespace SchoolGradingApi.entities
{
    // Table: school_settings  (ONE row only, Id = 1)
    // School-wide settings. For now just the Result Date that the Principal / VP sets.
    // The automatic deadline reminders for teachers count the days left until this date.
    public class SchoolSettings
    {
        public int Id { get; set; }

        // The day results are announced. null = not set yet.
        // DateOnly = a date without a time (MySQL column type DATE).
        public DateOnly? ResultDate { get; set; }

        // Foreign key -> users.Id (the Principal / VP who last changed it)
        public int? UpdatedByUserId { get; set; }
        public AppUser? UpdatedByUser { get; set; }

        public DateTime? UpdatedAt { get; set; }
    }
}
