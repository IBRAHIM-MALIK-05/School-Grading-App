namespace SchoolGradingApi.entities
{
    // Table: classes  (e.g. "Class 8" section "B")
    // Called SchoolClass because "class" is a C# keyword.
    public class SchoolClass
    {
        public int Id { get; set; }

        public string GradeName { get; set; } = "";   // "Class 8"

        public string Section { get; set; } = "";     // "B"

        // Foreign key -> users.Id (optional: a class may have no class teacher)
        public int? ClassTeacherId { get; set; }
        public AppUser? ClassTeacher { get; set; }

        // null = not published. A date = results published, marks are locked.
        public DateTime? ResultsPublishedAt { get; set; }

        // Navigation lists (one class has many students / subjects)
        public List<Student> Students { get; set; } = new List<Student>();
        public List<TeachingAssignment> Assignments { get; set; } = new List<TeachingAssignment>();
    }
}
