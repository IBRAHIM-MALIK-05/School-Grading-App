namespace SchoolGradingApi.Dtos
{
    // One subject of a class (who teaches it, is it submitted?)
    public class ClassSubjectDto
    {
        public int AssignmentId { get; set; }
        public int SubjectId { get; set; }
        public string SubjectName { get; set; } = "";
        public int MaxMarks { get; set; }
        public int? TeacherId { get; set; }
        public string? TeacherName { get; set; }
        public bool IsSubmitted { get; set; }
    }

    public class SchoolClassDto
    {
        public int Id { get; set; }
        public string GradeName { get; set; } = "";
        public string Section { get; set; } = "";
        public int? ClassTeacherId { get; set; }
        public string? ClassTeacherName { get; set; }
        public int StudentCount { get; set; }
        public bool IsPublished { get; set; }
        public List<ClassSubjectDto> Subjects { get; set; } = new List<ClassSubjectDto>();
    }

    // GET /api/classes  (Admin + Principal/VP overview)
    public class OverviewDto
    {
        public int Sections { get; set; }
        public int Students { get; set; }
        public int Teachers { get; set; }
        public int CardsReady { get; set; }        // students in published classes
        public int PendingSubjects { get; set; }   // class-subjects not submitted yet
        public List<SchoolClassDto> Classes { get; set; } = new List<SchoolClassDto>();
    }

    // One line of the Class Teacher's tracker
    public class SubjectStatusDto
    {
        public string SubjectName { get; set; } = "";
        public int MaxMarks { get; set; }
        public string TeacherName { get; set; } = "";
        public int EnteredCount { get; set; }
        public int StudentCount { get; set; }
        public DateTime? SubmittedAt { get; set; }
    }

    // GET /api/classes/{id}/tracker
    public class TrackerDto
    {
        public SchoolClassDto SchoolClass { get; set; } = new SchoolClassDto();
        public List<SubjectStatusDto> Subjects { get; set; } = new List<SubjectStatusDto>();
        public List<StudentDto> Students { get; set; } = new List<StudentDto>();
    }

    // PUT /api/classes/{id}/publish
    public class PublishDto
    {
        public bool Publish { get; set; }   // true = publish (lock), false = unpublish
    }
}
