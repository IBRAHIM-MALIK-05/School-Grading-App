namespace SchoolGradingApi.entities
{
    // Table: teaching_assignments
    // "Teacher X teaches subject Y in class Z" + has the teacher submitted marks?
    public class TeachingAssignment
    {
        public int Id { get; set; }

        // Foreign key -> classes.Id
        public int ClassId { get; set; }
        public SchoolClass? SchoolClass { get; set; }

        // Foreign key -> subjects.Id
        public int SubjectId { get; set; }
        public Subject? Subject { get; set; }

        // Foreign key -> users.Id (the subject teacher)
        public int TeacherId { get; set; }
        public AppUser? Teacher { get; set; }

        // null = not submitted yet. Set when the teacher presses "Submit".
        public DateTime? SubmittedAt { get; set; }
    }
}
