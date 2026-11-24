namespace SchoolGradingApi.entities
{
    // Table: subjects  (English 100, Mathematics 100, Physics 60, ...)
    public class Subject
    {
        public int Id { get; set; }

        public string Name { get; set; } = "";

        public int MaxMarks { get; set; }
    }
}
