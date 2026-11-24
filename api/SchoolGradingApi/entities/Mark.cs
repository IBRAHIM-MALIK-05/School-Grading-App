namespace SchoolGradingApi.entities
{
    // Table: marks  (one row = one student's marks in one subject)
    public class Mark
    {
        public int Id { get; set; }

        // Foreign key -> students.Id
        public int StudentId { get; set; }
        public Student? Student { get; set; }

        // Foreign key -> subjects.Id
        public int SubjectId { get; set; }
        public Subject? Subject { get; set; }

        public int Obtained { get; set; }

        // Foreign key -> users.Id (which teacher entered it)
        public int EnteredById { get; set; }
        public AppUser? EnteredBy { get; set; }

        public DateTime UpdatedAt { get; set; }
    }
}
