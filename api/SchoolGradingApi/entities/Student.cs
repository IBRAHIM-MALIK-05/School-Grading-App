namespace SchoolGradingApi.entities
{
    // Table: students
    public class Student
    {
        public int Id { get; set; }

        public string FullName { get; set; } = "";

        public string RollNo { get; set; } = "";   // "01", "02" ...

        // Foreign key -> classes.Id
        public int ClassId { get; set; }
        public SchoolClass? SchoolClass { get; set; }

        // One student has many marks (one per subject)
        public List<Mark> Marks { get; set; } = new List<Mark>();
    }
}
