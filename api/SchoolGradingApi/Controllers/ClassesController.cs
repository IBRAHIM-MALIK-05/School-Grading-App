using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    [Route("api/classes")]
    public class ClassesController : AppControllerBase
    {
        public ClassesController(AppDbContext db) : base(db)
        {
        }

        // Loads classes together with their teacher, students and subjects (JOINs)
        private IQueryable<SchoolClass> ClassesWithDetails()
        {
            return _db.Classes
                .Include(c => c.ClassTeacher)
                .Include(c => c.Students)
                .Include(c => c.Assignments).ThenInclude(a => a.Subject)
                .Include(c => c.Assignments).ThenInclude(a => a.Teacher);
        }

        // 6) GET /api/classes  -> school overview (Admin + Principal/VP)
        [HttpGet]
        public IActionResult GetOverview()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin" && me.Role != "vp") return Error(403, "Only the Admin or Principal/VP can see the overview.");

            var classes = ClassesWithDetails().OrderBy(c => c.Id).ToList();

            var overview = new OverviewDto
            {
                Sections = classes.Count,
                Students = classes.Sum(c => c.Students.Count),
                Teachers = _db.Users.Count(u => u.Role == "teacher"),
                CardsReady = classes.Where(c => c.ResultsPublishedAt != null).Sum(c => c.Students.Count),
                PendingSubjects = classes.Sum(c => c.Assignments.Count(a => a.SubmittedAt == null)),
                Classes = classes.Select(c => DtoMapper.ToSchoolClassDto(c)).ToList()
            };
            return Ok(overview);
        }

        // 7) GET /api/classes/{id}/tracker  -> which subject teachers have uploaded marks
        [HttpGet("{id}/tracker")]
        public IActionResult GetTracker(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var schoolClass = ClassesWithDetails().FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");
            if (!CanViewResults(me, schoolClass))
                return Error(403, "Only the Class Teacher of " + DtoMapper.ClassName(schoolClass) + " can view this.");

            int studentCount = schoolClass.Students.Count;
            var tracker = new TrackerDto
            {
                SchoolClass = DtoMapper.ToSchoolClassDto(schoolClass),
                Students = schoolClass.Students.OrderBy(s => s.RollNo).Select(s => DtoMapper.ToStudentDto(s)).ToList(),
                Subjects = schoolClass.Assignments
                    .OrderBy(a => a.SubjectId)
                    .Select(a => new SubjectStatusDto
                    {
                        SubjectName = a.Subject!.Name,
                        MaxMarks = a.Subject.MaxMarks,
                        TeacherName = a.Teacher?.FullName ?? "-",
                        EnteredCount = CountEnteredMarks(schoolClass.Id, a.SubjectId),
                        StudentCount = studentCount,
                        SubmittedAt = a.SubmittedAt
                    })
                    .ToList()
            };
            return Ok(tracker);
        }

        // 8) PUT /api/classes/{id}/publish  -> Class Teacher publishes (locks) or unpublishes results
        [HttpPut("{id}/publish")]
        public IActionResult SetPublished(int id, PublishDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var schoolClass = ClassesWithDetails().FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");
            if (schoolClass.ClassTeacherId != me.Id) return Error(403, "Only the Class Teacher can publish results.");

            if (dto.Publish)
            {
                var pending = schoolClass.Assignments
                    .Where(a => a.SubmittedAt == null)
                    .OrderBy(a => a.SubjectId)
                    .Select(a => a.Subject!.Name)
                    .ToList();
                if (pending.Count > 0)
                {
                    return Error(409, "Cannot publish yet. Still waiting for: " + string.Join(", ", pending) + ".");
                }
                schoolClass.ResultsPublishedAt = DateTime.UtcNow;
            }
            else
            {
                schoolClass.ResultsPublishedAt = null;
            }
            _db.SaveChanges();

            return Ok(new { message = dto.Publish ? "Results published." : "Results unpublished." });
        }

        // 9) GET /api/classes/{id}/students  -> students of one class (Manage Students screen)
        [HttpGet("{id}/students")]
        public IActionResult GetStudents(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var schoolClass = _db.Classes.Include(c => c.Students).FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");
            if (!CanManageStudents(me, schoolClass)) return Error(403, "You can only manage students of your own classes.");

            return Ok(new ClassStudentsDto
            {
                ClassId = schoolClass.Id,
                ClassName = DtoMapper.ClassName(schoolClass),
                IsPublished = schoolClass.ResultsPublishedAt != null,
                Students = schoolClass.Students.OrderBy(s => s.RollNo).Select(s => DtoMapper.ToStudentDto(s)).ToList()
            });
        }

        // 10) POST /api/classes/{id}/students  -> add a student to a class
        [HttpPost("{id}/students")]
        public IActionResult AddStudent(int id, AddStudentDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var schoolClass = _db.Classes.FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");
            if (!CanManageStudents(me, schoolClass)) return Error(403, "You can only manage students of your own classes.");

            var fullName = dto.FullName.Trim();
            var rollNo = dto.RollNo.Trim();
            if (fullName == "" || rollNo == "") return Error(400, "Name and roll number are required.");
            if (int.TryParse(rollNo, out int number)) rollNo = number.ToString("00");   // 7 -> "07"

            if (schoolClass.ResultsPublishedAt != null)
                return Error(409, "Results of " + DtoMapper.ClassName(schoolClass) + " are published. Unpublish first.");
            if (_db.Students.Any(s => s.ClassId == id && s.RollNo == rollNo))
                return Error(409, "Roll number " + rollNo + " already exists in " + DtoMapper.ClassName(schoolClass) + ".");

            var student = new Student { FullName = fullName, RollNo = rollNo, ClassId = id };
            _db.Students.Add(student);

            // The new student has no marks yet, so no subject of this class can stay
            // "submitted" -> the Class Teacher's tracker stays accurate.
            foreach (var assignment in _db.TeachingAssignments.Where(a => a.ClassId == id))
            {
                assignment.SubmittedAt = null;
            }
            _db.SaveChanges();

            return StatusCode(201, DtoMapper.ToStudentDto(student));
        }
    }
}
