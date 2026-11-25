namespace SchoolGradingApi.Dtos
{
    // GET /api/assignments/mine  (one subject + class the teacher teaches)
    public class TeacherAssignmentDto
    {
        public int Id { get; set; }
        public int ClassId { get; set; }
        public string ClassName { get; set; } = "";
        public int SubjectId { get; set; }
        public string SubjectName { get; set; } = "";
        public int MaxMarks { get; set; }
        public int StudentCount { get; set; }
        public int EnteredCount { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public bool IsClassPublished { get; set; }
    }

    // One line on the Marks Entry screen
    public class MarkRowDto
    {
        public int StudentId { get; set; }
        public string StudentName { get; set; } = "";
        public string RollNo { get; set; } = "";
        public int? Obtained { get; set; }   // null = no mark yet
    }

    // "Ali (roll 06) was removed by the Class Teacher of Class 8 - B"
    public class RemovalNoticeDto
    {
        public string StudentName { get; set; } = "";
        public string RollNo { get; set; } = "";
        public string Message { get; set; } = "";
        public DateTime RemovedAt { get; set; }
    }

    // GET /api/assignments/{id}/marks
    public class AssignmentMarksDto
    {
        public TeacherAssignmentDto Assignment { get; set; } = new TeacherAssignmentDto();
        public List<MarkRowDto> Rows { get; set; } = new List<MarkRowDto>();
        // Students recently deleted from this class (last 30 days, newest first)
        public List<RemovalNoticeDto> RemovedStudents { get; set; } = new List<RemovalNoticeDto>();
    }

    // PUT /api/assignments/{id}/marks  (upload + update in one call)
    public class SaveMarksDto
    {
        public List<MarkEntryDto> Marks { get; set; } = new List<MarkEntryDto>();
        public bool Submit { get; set; }   // false = save progress, true = final submit to Class Teacher
    }

    public class MarkEntryDto
    {
        public int StudentId { get; set; }
        public int? Obtained { get; set; }   // null = remove this student's mark
    }
}
