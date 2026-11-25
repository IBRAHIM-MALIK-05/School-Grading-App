using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    [Route("api/students")]
    public class StudentsController : AppControllerBase
    {
        public StudentsController(AppDbContext db) : base(db)
        {
        }

        // 11) DELETE /api/students/{id}  -> delete a student (and ALL their marks)
        //     Only the Class Teacher of the student's class, or the Admin.
        //     (There is deliberately NO "edit student" endpoint: a wrong entry is deleted and added again.)
        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var student = _db.Students.Include(s => s.SchoolClass).FirstOrDefault(s => s.Id == id);
            if (student == null) return Error(404, "Student not found.");

            var schoolClass = student.SchoolClass!;
            if (!CanManageStudents(me, schoolClass)) return OnlyClassTeacherOrAdmin(schoolClass);
            if (schoolClass.ResultsPublishedAt != null)
                return Error(409, "Results of " + DtoMapper.ClassName(schoolClass) + " are published. Unpublish first.");

            string className = DtoMapper.ClassName(schoolClass);
            string removedBy = me.Role == "admin" ? "Admin" : "Class Teacher";

            // Delete every mark of this student explicitly (all subjects of the class),
            // then the student; and leave a notice for the subject teachers. One save = one transaction.
            var marks = _db.Marks.Where(m => m.StudentId == student.Id).ToList();
            _db.Marks.RemoveRange(marks);
            _db.Students.Remove(student);
            _db.StudentRemovals.Add(new StudentRemoval
            {
                ClassId = schoolClass.Id,
                StudentName = student.FullName,
                RollNo = student.RollNo,
                RemovedById = me.Id,
                RemovedByRole = removedBy,
                RemovedAt = DateTime.UtcNow
            });
            _db.SaveChanges();

            return Ok(new
            {
                message = student.FullName + " was deleted from " + className + " by the " + removedBy +
                          " (removed from all subjects).",
                marksDeleted = marks.Count
            });
        }

        // 12) GET /api/students/{id}/report-card  -> the student's result card
        [HttpGet("{id}/report-card")]
        public IActionResult GetReportCard(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var student = _db.Students
                .Include(s => s.SchoolClass).ThenInclude(c => c!.ClassTeacher)
                .Include(s => s.SchoolClass).ThenInclude(c => c!.Assignments).ThenInclude(a => a.Subject)
                .Include(s => s.Marks)
                .FirstOrDefault(s => s.Id == id);
            if (student == null) return Error(404, "Student not found.");

            var schoolClass = student.SchoolClass!;
            if (!CanViewResults(me, schoolClass))
                return Error(403, "Only the Class Teacher of " + DtoMapper.ClassName(schoolClass) + " can view this.");

            // One line per subject of the class
            var lines = schoolClass.Assignments
                .OrderBy(a => a.SubjectId)
                .Select(a => new ReportLineDto
                {
                    SubjectName = a.Subject!.Name,
                    MaxMarks = a.Subject.MaxMarks,
                    Obtained = student.Marks.FirstOrDefault(m => m.SubjectId == a.SubjectId)?.Obtained
                })
                .ToList();

            int totalMax = lines.Sum(l => l.MaxMarks);
            int totalObtained = lines.Sum(l => l.Obtained ?? 0);
            bool isComplete = lines.All(l => l.Obtained != null);

            double? percentage = null;
            string? grade = null;
            if (isComplete && totalMax > 0)
            {
                percentage = Math.Round(totalObtained * 100.0 / totalMax, 1);
                grade = GradeHelper.GetGrade(percentage.Value);
            }

            return Ok(new ReportCardDto
            {
                SchoolName = GradeHelper.SchoolName,
                ClassId = schoolClass.Id,
                StudentName = student.FullName,
                RollNo = student.RollNo,
                ClassName = DtoMapper.ClassName(schoolClass),
                ClassTeacherName = schoolClass.ClassTeacher?.FullName,
                Lines = lines,
                TotalObtained = totalObtained,
                TotalMax = totalMax,
                Percentage = percentage,
                Grade = grade,
                IsComplete = isComplete,
                IsPublished = schoolClass.ResultsPublishedAt != null,
                CanPrint = schoolClass.ClassTeacherId == me.Id   // Admin / VP: view only
            });
        }
    }
}
