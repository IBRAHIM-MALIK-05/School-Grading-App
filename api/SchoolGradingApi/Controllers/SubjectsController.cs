using Microsoft.AspNetCore.Mvc;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;

namespace SchoolGradingApi.Controllers
{
    [Route("api/subjects")]
    public class SubjectsController : AppControllerBase
    {
        public SubjectsController(AppDbContext db) : base(db)
        {
        }

        // 18) GET /api/subjects  -> every subject (Admin's "Manage Classes" form)
        [HttpGet]
        public IActionResult GetAll()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can manage classes and subjects.");

            var subjects = _db.Subjects
                .OrderBy(s => s.Id)
                .Select(s => new SubjectDto { Id = s.Id, Name = s.Name, MaxMarks = s.MaxMarks })
                .ToList();
            return Ok(subjects);
        }
    }
}
