using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    // A "teaching assignment" = one teacher + one subject + one class
    [Route("api/assignments")]
    public class AssignmentsController : AppControllerBase
    {
        public AssignmentsController(AppDbContext db) : base(db)
        {
        }

        private TeacherAssignmentDto ToDto(TeachingAssignment a)
        {
            return new TeacherAssignmentDto
            {
                Id = a.Id,
                ClassId = a.ClassId,
                ClassName = DtoMapper.ClassName(a.SchoolClass!),
                SubjectId = a.SubjectId,
                SubjectName = a.Subject!.Name,
                MaxMarks = a.Subject.MaxMarks,
                StudentCount = _db.Students.Count(s => s.ClassId == a.ClassId),
                EnteredCount = CountEnteredMarks(a.ClassId, a.SubjectId),
                SubmittedAt = a.SubmittedAt,
                IsClassPublished = a.SchoolClass!.ResultsPublishedAt != null
            };
        }

        private TeachingAssignment? FindAssignment(int id)
        {
            return _db.TeachingAssignments
                .Include(a => a.SchoolClass)
                .Include(a => a.Subject)
                .FirstOrDefault(a => a.Id == id);
        }

        // 13) GET /api/assignments/mine  -> subjects/classes of the logged-in teacher
        [HttpGet("mine")]
        public IActionResult GetMine()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "teacher") return Error(403, "Only teachers have subjects.");

            var mine = _db.TeachingAssignments
                .Include(a => a.SchoolClass)
                .Include(a => a.Subject)
                .Where(a => a.TeacherId == me.Id)
                .OrderBy(a => a.SubjectId).ThenBy(a => a.ClassId)
                .ToList();

            return Ok(mine.Select(a => ToDto(a)).ToList());
        }

        // 14) GET /api/assignments/{id}/marks  -> students + their current marks
        [HttpGet("{id}/marks")]
        public IActionResult GetMarks(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var assignment = FindAssignment(id);
            if (assignment == null) return Error(404, "Assignment not found.");
            if (assignment.TeacherId != me.Id) return Error(403, "This subject/class is not assigned to you.");

            var students = _db.Students
                .Where(s => s.ClassId == assignment.ClassId)
                .OrderBy(s => s.RollNo)
                .ToList();
            var marks = _db.Marks
                .Where(m => m.SubjectId == assignment.SubjectId && m.Student!.ClassId == assignment.ClassId)
                .ToList();

            // Students the Class Teacher (or Admin) deleted from this class in the last 30 days,
            // so the subject teacher knows why a name disappeared from the list.
            string className = DtoMapper.ClassName(assignment.SchoolClass!);
            var since = DateTime.UtcNow.AddDays(-30);
            var removed = _db.StudentRemovals
                .Where(r => r.ClassId == assignment.ClassId && r.RemovedAt >= since)
                .OrderByDescending(r => r.RemovedAt)
                .Take(10)
                .ToList();

            return Ok(new AssignmentMarksDto
            {
                Assignment = ToDto(assignment),
                Rows = students.Select(s => new MarkRowDto
                {
                    StudentId = s.Id,
                    StudentName = s.FullName,
                    RollNo = s.RollNo,
                    Obtained = marks.FirstOrDefault(m => m.StudentId == s.Id)?.Obtained
                }).ToList(),
                RemovedStudents = removed.Select(r => new RemovalNoticeDto
                {
                    StudentName = r.StudentName,
                    RollNo = r.RollNo,
                    RemovedAt = r.RemovedAt,
                    Message = r.StudentName + " (roll " + r.RollNo + ") was removed by the " +
                              (r.RemovedByRole == "Admin" ? "Admin" : "Class Teacher of " + className) +
                              " - their marks were deleted from every subject."
                }).ToList()
            });
        }

        // 15) PUT /api/assignments/{id}/marks  -> upload / update marks (save progress or final submit)
        [HttpPut("{id}/marks")]
        public IActionResult SaveMarks(int id, SaveMarksDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var assignment = FindAssignment(id);
            if (assignment == null) return Error(404, "Assignment not found.");
            if (assignment.TeacherId != me.Id) return Error(403, "This subject/class is not assigned to you.");

            var schoolClass = assignment.SchoolClass!;
            var subject = assignment.Subject!;
            if (schoolClass.ResultsPublishedAt != null)
                return Error(409, "Results of " + DtoMapper.ClassName(schoolClass) + " are published. Marks are locked.");

            var studentIds = _db.Students.Where(s => s.ClassId == schoolClass.Id).Select(s => s.Id).ToList();

            // 1) Check everything first, so nothing is half-saved
            foreach (var entry in dto.Marks)
            {
                if (!studentIds.Contains(entry.StudentId))
                    return Error(400, "Student " + entry.StudentId + " is not in " + DtoMapper.ClassName(schoolClass) + ".");
                if (entry.Obtained != null && (entry.Obtained < 0 || entry.Obtained > subject.MaxMarks))
                    return Error(400, "Marks must be between 0 and " + subject.MaxMarks + ".");
            }

            // 2) Insert / update / remove each mark
            var existingMarks = _db.Marks
                .Where(m => m.SubjectId == subject.Id && studentIds.Contains(m.StudentId))
                .ToList();

            foreach (var entry in dto.Marks)
            {
                var existing = existingMarks.FirstOrDefault(m => m.StudentId == entry.StudentId);
                if (entry.Obtained == null)
                {
                    if (existing != null)
                    {
                        _db.Marks.Remove(existing);
                        existingMarks.Remove(existing);
                    }
                }
                else if (existing == null)
                {
                    var mark = new Mark
                    {
                        StudentId = entry.StudentId,
                        SubjectId = subject.Id,
                        Obtained = entry.Obtained.Value,
                        EnteredById = me.Id,
                        UpdatedAt = DateTime.UtcNow
                    };
                    _db.Marks.Add(mark);
                    existingMarks.Add(mark);
                }
                else
                {
                    existing.Obtained = entry.Obtained.Value;
                    existing.EnteredById = me.Id;
                    existing.UpdatedAt = DateTime.UtcNow;
                }
            }

            // 3) Submitted or not?  An incomplete subject can never stay "submitted"
            //    (e.g. a mark was cleared), whether this was a progress save or a failed submit.
            int missing = studentIds.Count - existingMarks.Count;
            if (missing > 0)
            {
                assignment.SubmittedAt = null;
            }
            else if (dto.Submit)
            {
                assignment.SubmittedAt = DateTime.UtcNow;
            }
            _db.SaveChanges();   // one save: the typed marks + the submitted flag together

            if (dto.Submit && missing > 0)
                return Error(400, "Marks saved, but cannot submit: " + missing + " student(s) still have no marks.");

            // Submitted: the Class Teacher's reminders about THIS subject + class are marked read.
            // Was it also the teacher's last pending subject? Then the automatic Result Date
            // reminders stop bothering them (their unread deadline_* notifications are marked read).
            if (dto.Submit)
            {
                DeadlineReminders.ClearClassTeacherReminders(_db, me.Id, assignment.Id);
                DeadlineReminders.StopIfAllSubmitted(_db, me.Id);
            }

            return Ok(new { message = dto.Submit ? "Marks submitted." : "Progress saved (not submitted yet)." });
        }
    }
}
