using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    [Route("api/students")]
    public class StudentsController : AppControllerBase
    {
        public StudentsController(AppDbContext db) : base(db)
        {
        }

        // 11) DELETE /api/students/{id}  -> delete a student (and their marks)
        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var student = _db.Students.Include(s => s.SchoolClass).FirstOrDefault(s => s.Id == id);
            if (student == null) return Error(404, "Student not found.");

            var schoolClass = student.SchoolClass!;
            if (!CanManageStudents(me, schoolClass)) return Error(403, "You can only manage students of your own classes.");
            if (schoolClass.ResultsPublishedAt != null)
                return Error(409, "Results of " + DtoMapper.ClassName(schoolClass) + " are published. Unpublish first.");

            _db.Students.Remove(student);   // marks are deleted too (ON DELETE CASCADE)
            _db.SaveChanges();

            return Ok(new { message = student.FullName + " deleted." });
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
                IsPublished = schoolClass.ResultsPublishedAt != null
            });
        }
    }
}
