namespace SchoolGradingApi.entities
{
    // Table: student_removals
    // A short notice saved when a student is deleted, so the SUBJECT teachers of that
    // class can see "Ali was removed by the Class Teacher of Class 8 - B" instead of
    // wondering why the student vanished from their marks list.
    // (The student row and all their marks are really deleted; only this notice stays.)
    public class StudentRemoval
    {
        public int Id { get; set; }

        // Foreign key -> classes.Id
        public int ClassId { get; set; }
        public SchoolClass? SchoolClass { get; set; }

        // Copied, because the student row no longer exists
        public string StudentName { get; set; } = "";
        public string RollNo { get; set; } = "";

        // Foreign key -> users.Id (who deleted the student)
        public int RemovedById { get; set; }
        public AppUser? RemovedBy { get; set; }

        // "Class Teacher" or "Admin"
        public string RemovedByRole { get; set; } = "";

        public DateTime RemovedAt { get; set; }
    }
}
