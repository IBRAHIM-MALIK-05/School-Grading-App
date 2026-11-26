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
        public int AssignmentId { get; set; }     // for the Class Teacher's "Notify" button
        public int TeacherId { get; set; }
        public string SubjectName { get; set; } = "";
        public int MaxMarks { get; set; }
        public string TeacherName { get; set; } = "";
        public int EnteredCount { get; set; }
        public int StudentCount { get; set; }
        public DateTime? SubmittedAt { get; set; }
    }

    // One subject a student's result card is still waiting for
    public class WaitingOnDto
    {
        public string SubjectName { get; set; } = "";
        public string TeacherName { get; set; } = "";
        public string Reason { get; set; } = "";   // "no mark entered yet" / "not submitted yet"
    }

    // Is this student's result card ready? If not: exactly which subject(s) + teacher(s)
    public class StudentReadinessDto
    {
        public int StudentId { get; set; }
        public string FullName { get; set; } = "";
        public string RollNo { get; set; } = "";
        public bool IsReady { get; set; }   // every subject submitted AND has a mark for this student
        public List<WaitingOnDto> WaitingOn { get; set; } = new List<WaitingOnDto>();
    }

    // GET /api/classes/{id}/tracker
    public class TrackerDto
    {
        public SchoolClassDto SchoolClass { get; set; } = new SchoolClassDto();
        public List<SubjectStatusDto> Subjects { get; set; } = new List<SubjectStatusDto>();
        public List<StudentDto> Students { get; set; } = new List<StudentDto>();
        public List<StudentReadinessDto> Readiness { get; set; } = new List<StudentReadinessDto>();
    }

    // One subject + its teacher, used when the Admin creates a class or changes its teachers.
    // TeacherId = null (only in PUT .../assignments) removes that subject from the class.
    public class SubjectTeacherDto
    {
        public int SubjectId { get; set; }
        public int? TeacherId { get; set; }
    }

    // POST /api/classes  (Admin creates a class)
    public class CreateClassDto
    {
        public const int MaxGradeNameLength = 20;   // classes.GradeName
        public const int MaxSectionLength = 5;      // classes.Section

        public string GradeName { get; set; } = "";   // "Class 10"
        public string Section { get; set; } = "";     // "A"
        public int? ClassTeacherId { get; set; }      // optional
        public List<SubjectTeacherDto> SubjectTeachers { get; set; } = new List<SubjectTeacherDto>();
    }

    // PUT /api/classes/{id}/assignments  (Admin changes the Class Teacher / subject teachers)
    // ClassTeacherId: the class teacher after saving (null = none).
    // SubjectTeachers: only the subjects listed are changed; others stay as they are.
    public class ClassTeachersDto
    {
        public int? ClassTeacherId { get; set; }
        public List<SubjectTeacherDto> SubjectTeachers { get; set; } = new List<SubjectTeacherDto>();
    }

    // GET /api/subjects
    public class SubjectDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public int MaxMarks { get; set; }
        public int ClassCount { get; set; }   // in how many classes it is taught
    }

    // POST /api/subjects and PUT /api/subjects/{id}
    public class SaveSubjectDto
    {
        public const int MaxNameLength = 50;     // subjects.Name
        public const int HighestMaxMarks = 1000;

        public string Name { get; set; } = "";
        public int MaxMarks { get; set; } = 100;
    }

    // PUT /api/classes/{id}/publish
    public class PublishDto
    {
        public bool Publish { get; set; }   // true = publish (lock), false = unpublish
    }
}
