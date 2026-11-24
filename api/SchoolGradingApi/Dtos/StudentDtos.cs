namespace SchoolGradingApi.Dtos
{
    public class StudentDto
    {
        public int Id { get; set; }
        public string FullName { get; set; } = "";
        public string RollNo { get; set; } = "";
        public int ClassId { get; set; }
    }

    // POST /api/classes/{id}/students
    public class AddStudentDto
    {
        public string FullName { get; set; } = "";
        public string RollNo { get; set; } = "";
    }

    // GET /api/classes/{id}/students
    public class ClassStudentsDto
    {
        public int ClassId { get; set; }
        public string ClassName { get; set; } = "";
        public bool IsPublished { get; set; }   // true = cannot add / delete students
        public List<StudentDto> Students { get; set; } = new List<StudentDto>();
    }

    public class ReportLineDto
    {
        public string SubjectName { get; set; } = "";
        public int MaxMarks { get; set; }
        public int? Obtained { get; set; }   // null = not entered yet
    }

    // GET /api/students/{id}/report-card
    public class ReportCardDto
    {
        public string SchoolName { get; set; } = "";
        public string StudentName { get; set; } = "";
        public string RollNo { get; set; } = "";
        public string ClassName { get; set; } = "";
        public string? ClassTeacherName { get; set; }
        public List<ReportLineDto> Lines { get; set; } = new List<ReportLineDto>();
        public int TotalObtained { get; set; }
        public int TotalMax { get; set; }
        public double? Percentage { get; set; }   // null while incomplete
        public string? Grade { get; set; }        // null while incomplete
        public bool IsComplete { get; set; }
        public bool IsPublished { get; set; }
    }
}
