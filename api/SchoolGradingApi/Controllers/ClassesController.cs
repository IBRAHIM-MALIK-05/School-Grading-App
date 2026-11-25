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

        // 7) GET /api/classes/{id}/tracker  -> which subjects are submitted + which result cards are ready
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

            // Which (student, subject) pairs already have a mark - ONE query for the whole class
            var marked = _db.Marks
                .Where(m => m.Student!.ClassId == id)
                .Select(m => new { m.StudentId, m.SubjectId })
                .ToList()
                .Select(m => (m.StudentId, m.SubjectId))
                .ToHashSet();

            var assignments = schoolClass.Assignments.OrderBy(a => a.SubjectId).ToList();
            var students = schoolClass.Students.OrderBy(s => s.RollNo).ToList();
            int studentCount = students.Count;

            var tracker = new TrackerDto
            {
                SchoolClass = DtoMapper.ToSchoolClassDto(schoolClass),
                Students = students.Select(s => DtoMapper.ToStudentDto(s)).ToList(),
                Subjects = assignments
                    .Select(a => new SubjectStatusDto
                    {
                        SubjectName = a.Subject!.Name,
                        MaxMarks = a.Subject.MaxMarks,
                        TeacherName = a.Teacher?.FullName ?? "-",
                        EnteredCount = students.Count(s => marked.Contains((s.Id, a.SubjectId))),
                        StudentCount = studentCount,
                        SubmittedAt = a.SubmittedAt
                    })
                    .ToList()
            };

            // Per student: ready, or exactly which subject (and teacher) the card is waiting for
            foreach (var s in students)
            {
                var readiness = new StudentReadinessDto { StudentId = s.Id, FullName = s.FullName, RollNo = s.RollNo };
                foreach (var a in assignments)
                {
                    string? reason = null;
                    if (!marked.Contains((s.Id, a.SubjectId))) reason = "no mark entered yet";
                    else if (a.SubmittedAt == null) reason = "not submitted yet";

                    if (reason != null)
                    {
                        readiness.WaitingOn.Add(new WaitingOnDto
                        {
                            SubjectName = a.Subject!.Name,
                            TeacherName = a.Teacher?.FullName ?? "-",
                            Reason = reason
                        });
                    }
                }
                readiness.IsReady = assignments.Count > 0 && readiness.WaitingOn.Count == 0;
                tracker.Readiness.Add(readiness);
            }
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
                // A subject is ready only if it was submitted AND every student really has a mark
                int studentCount = schoolClass.Students.Count;
                var pending = schoolClass.Assignments
                    .Where(a => a.SubmittedAt == null || CountEnteredMarks(schoolClass.Id, a.SubjectId) < studentCount)
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
        //    Only the Class Teacher of this class or the Admin.
        [HttpGet("{id}/students")]
        public IActionResult GetStudents(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var schoolClass = _db.Classes.Include(c => c.Students).FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");
            if (!CanManageStudents(me, schoolClass)) return OnlyClassTeacherOrAdmin(schoolClass);

            return Ok(new ClassStudentsDto
            {
                ClassId = schoolClass.Id,
                ClassName = DtoMapper.ClassName(schoolClass),
                IsPublished = schoolClass.ResultsPublishedAt != null,
                Students = schoolClass.Students.OrderBy(s => s.RollNo).Select(s => DtoMapper.ToStudentDto(s)).ToList()
            });
        }

        // 10) POST /api/classes/{id}/students  -> add a student to a class
        //     Only the Class Teacher of this class or the Admin.
        [HttpPost("{id}/students")]
        public IActionResult AddStudent(int id, AddStudentDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var schoolClass = _db.Classes.FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");
            if (!CanManageStudents(me, schoolClass)) return OnlyClassTeacherOrAdmin(schoolClass);

            var fullName = (dto.FullName ?? "").Trim();
            var rollNo = (dto.RollNo ?? "").Trim();
            if (fullName == "" || rollNo == "") return Error(400, "Name and roll number are required.");
            if (fullName.Length > AddStudentDto.MaxNameLength)
                return Error(400, "Name can be at most " + AddStudentDto.MaxNameLength + " characters.");
            // Check the length of what was TYPED, before "00000000089" is shortened to "89"
            if (rollNo.Length > AddStudentDto.MaxRollNoLength)
                return Error(400, "Roll number can be at most " + AddStudentDto.MaxRollNoLength + " characters.");
            if (int.TryParse(rollNo, out int number))
            {
                if (number < 0) return Error(400, "Roll number cannot be negative.");
                rollNo = number.ToString("00");   // 7 -> "07"
            }

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

        // 16) POST /api/classes  -> Admin creates a new class (+ optional Class Teacher and subject teachers)
        [HttpPost]
        public IActionResult CreateClass(CreateClassDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can create classes.");

            var gradeName = (dto.GradeName ?? "").Trim();
            var section = (dto.Section ?? "").Trim().ToUpperInvariant();
            var nameProblem = CheckClassName(gradeName, section, null);
            if (nameProblem != null) return nameProblem;

            var schoolClass = new SchoolClass { GradeName = gradeName, Section = section };

            if (dto.ClassTeacherId != null)
            {
                var problem = CheckClassTeacher(dto.ClassTeacherId.Value, null);
                if (problem != null) return problem;
                schoolClass.ClassTeacherId = dto.ClassTeacherId;
            }

            var subjectTeachers = (dto.SubjectTeachers ?? new List<SubjectTeacherDto>())
                .Where(st => st.TeacherId != null).ToList();
            var subjectProblem = CheckSubjectTeachers(subjectTeachers);
            if (subjectProblem != null) return subjectProblem;

            foreach (var st in subjectTeachers)
            {
                schoolClass.Assignments.Add(new TeachingAssignment { SubjectId = st.SubjectId, TeacherId = st.TeacherId!.Value });
            }

            _db.Classes.Add(schoolClass);
            _db.SaveChanges();   // class + its subject teachers in one transaction

            var created = ClassesWithDetails().First(c => c.Id == schoolClass.Id);
            return StatusCode(201, DtoMapper.ToSchoolClassDto(created));
        }

        // 17) PUT /api/classes/{id}/assignments  -> Admin changes the Class Teacher and/or subject teachers
        [HttpPut("{id}/assignments")]
        public IActionResult UpdateTeachers(int id, ClassTeachersDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can assign teachers to a class.");

            var schoolClass = ClassesWithDetails().FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");

            var problem = ApplyTeachers(schoolClass, dto.ClassTeacherId, dto.SubjectTeachers);
            if (problem != null) return problem;
            _db.SaveChanges();   // everything in one transaction

            var updated = ClassesWithDetails().First(c => c.Id == id);
            return Ok(DtoMapper.ToSchoolClassDto(updated));
        }

        // 23) PUT /api/classes/{id}  -> Admin edits EVERYTHING of a class at once:
        //     name + section, Class Teacher, subjects and their teachers (one transaction)
        [HttpPut("{id}")]
        public IActionResult EditClass(int id, CreateClassDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can edit classes.");

            var schoolClass = ClassesWithDetails().FirstOrDefault(c => c.Id == id);
            if (schoolClass == null) return Error(404, "Class not found.");

            var gradeName = (dto.GradeName ?? "").Trim();
            var section = (dto.Section ?? "").Trim().ToUpperInvariant();
            var problem = CheckClassName(gradeName, section, id);
            if (problem != null) return problem;

            problem = ApplyTeachers(schoolClass, dto.ClassTeacherId, dto.SubjectTeachers);
            if (problem != null) return problem;

            schoolClass.GradeName = gradeName;
            schoolClass.Section = section;
            _db.SaveChanges();   // name + teachers together (or nothing)

            var updated = ClassesWithDetails().First(c => c.Id == id);
            return Ok(DtoMapper.ToSchoolClassDto(updated));
        }

        // ----- helpers for create / update -----

        // Changes the Class Teacher (null = none) and the listed subjects (TeacherId null = remove).
        // Only marks changes in EF; the caller saves. Returns an error, or null when everything is OK.
        private IActionResult? ApplyTeachers(SchoolClass schoolClass, int? classTeacherId, List<SubjectTeacherDto>? subjectTeachers)
        {
            string className = DtoMapper.ClassName(schoolClass);
            bool isPublished = schoolClass.ResultsPublishedAt != null;

            // ----- Class Teacher -----
            if (classTeacherId != schoolClass.ClassTeacherId)
            {
                if (classTeacherId != null)
                {
                    var problem = CheckClassTeacher(classTeacherId.Value, schoolClass.Id);
                    if (problem != null) return problem;
                }
                schoolClass.ClassTeacherId = classTeacherId;
            }

            // ----- Subject teachers -----
            var changes = subjectTeachers ?? new List<SubjectTeacherDto>();
            var subjectProblem = CheckSubjectTeachers(changes);
            if (subjectProblem != null) return subjectProblem;

            foreach (var change in changes)
            {
                var existing = schoolClass.Assignments.FirstOrDefault(a => a.SubjectId == change.SubjectId);
                var subjectName = _db.Subjects.Where(s => s.Id == change.SubjectId).Select(s => s.Name).First();

                if (change.TeacherId == null)
                {
                    if (existing == null) continue;   // not taught in this class anyway
                    if (isPublished)
                        return Error(409, "Results of " + className + " are published. Unpublish first to remove a subject.");
                    if (CountEnteredMarks(schoolClass.Id, change.SubjectId) > 0)
                        return Error(409, subjectName + " already has marks in " + className + ", so it cannot be removed.");
                    _db.TeachingAssignments.Remove(existing);
                }
                else if (existing == null)
                {
                    if (isPublished)
                        return Error(409, "Results of " + className + " are published. Unpublish first to add a subject.");
                    _db.TeachingAssignments.Add(new TeachingAssignment
                    {
                        ClassId = schoolClass.Id, SubjectId = change.SubjectId, TeacherId = change.TeacherId.Value
                    });
                }
                else
                {
                    existing.TeacherId = change.TeacherId.Value;   // marks + submitted status are kept
                }
            }
            return null;
        }

        // Class name + section: required, not too long, and not used by ANOTHER class
        private IActionResult? CheckClassName(string gradeName, string section, int? thisClassId)
        {
            if (gradeName == "" || section == "")
                return Error(400, "Class name and section are required (e.g. \"Class 10\" and \"A\").");
            if (gradeName.Length > CreateClassDto.MaxGradeNameLength)
                return Error(400, "Class name can be at most " + CreateClassDto.MaxGradeNameLength + " characters.");
            if (section.Length > CreateClassDto.MaxSectionLength)
                return Error(400, "Section can be at most " + CreateClassDto.MaxSectionLength + " characters.");
            if (_db.Classes.Any(c => c.GradeName == gradeName && c.Section == section && c.Id != thisClassId))
                return Error(409, gradeName + " - " + section + " already exists.");
            return null;
        }

        // The user must exist, be a teacher, and not already lead ANOTHER class
        private IActionResult? CheckClassTeacher(int teacherId, int? thisClassId)
        {
            var teacher = _db.Users.FirstOrDefault(u => u.Id == teacherId);
            if (teacher == null || teacher.Role != "teacher")
                return Error(400, "The Class Teacher must be a teacher account.");
            var otherClass = _db.Classes.FirstOrDefault(c => c.ClassTeacherId == teacherId && c.Id != thisClassId);
            if (otherClass != null)
                return Error(409, teacher.FullName + " is already the Class Teacher of " + DtoMapper.ClassName(otherClass) + ".");
            return null;
        }

        // Every subject must exist (once), every teacher must be a teacher account
        private IActionResult? CheckSubjectTeachers(List<SubjectTeacherDto> subjectTeachers)
        {
            if (subjectTeachers.Select(st => st.SubjectId).Distinct().Count() != subjectTeachers.Count)
                return Error(400, "Each subject can be listed only once.");

            var subjectIds = subjectTeachers.Select(st => st.SubjectId).ToList();
            if (_db.Subjects.Count(s => subjectIds.Contains(s.Id)) != subjectIds.Count)
                return Error(400, "One or more subjects do not exist.");

            var teacherIds = subjectTeachers.Where(st => st.TeacherId != null).Select(st => st.TeacherId!.Value).Distinct().ToList();
            if (_db.Users.Count(u => teacherIds.Contains(u.Id) && u.Role == "teacher") != teacherIds.Count)
                return Error(400, "Every subject teacher must be a teacher account.");
            return null;
        }
    }
}
