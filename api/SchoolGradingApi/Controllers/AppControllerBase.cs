using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    // Parent class of all our controllers (inheritance), so common code is written once.
    [ApiController]
    [Authorize]   // every endpoint needs a valid JWT token, unless it says [AllowAnonymous]
    public abstract class AppControllerBase : ControllerBase
    {
        protected readonly AppDbContext _db;

        public AppControllerBase(AppDbContext db)
        {
            _db = db;
        }

        // Who is calling? Read the user id from the JWT, then load that user from MySQL.
        protected AppUser? GetCurrentUser()
        {
            var idText = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(idText, out int id))
            {
                return null;
            }
            return _db.Users.FirstOrDefault(u => u.Id == id);
        }

        // Every error is sent the same way: { "message": "..." }
        protected IActionResult Error(int statusCode, string message)
        {
            return StatusCode(statusCode, new { message = message });
        }

        protected IActionResult NotLoggedIn()
        {
            return Error(401, "Please log in again.");
        }

        protected IActionResult MustChangePasswordFirst()
        {
            return Error(403, "Please change your temporary password first.");
        }

        // A user + the class they are class teacher of (if any)
        protected UserDto MakeUserDto(AppUser user)
        {
            var myClass = _db.Classes.FirstOrDefault(c => c.ClassTeacherId == user.Id);
            return DtoMapper.ToUserDto(user, myClass);
        }

        // Who may see / add / delete the students of a class?
        // ONLY the Admin (any class) or the Class Teacher of THAT class.
        // A subject teacher who only teaches a subject there is NOT allowed (403):
        // they see their students on the marks screen instead.
        protected bool CanManageStudents(AppUser me, SchoolClass schoolClass)
        {
            if (me.Role == "admin") return true;
            return me.Role == "teacher" && schoolClass.ClassTeacherId == me.Id;
        }

        protected IActionResult OnlyClassTeacherOrAdmin(SchoolClass schoolClass)
        {
            return Error(403, "Only the Class Teacher of " + DtoMapper.ClassName(schoolClass) +
                              " or the Admin can add or delete its students.");
        }

        // Admin and Principal/VP: any class. Teacher: only the class they are class teacher of.
        protected bool CanViewResults(AppUser me, SchoolClass schoolClass)
        {
            if (me.Role == "admin" || me.Role == "vp") return true;
            return schoolClass.ClassTeacherId == me.Id;
        }

        // How many students of this class already have marks in this subject
        protected int CountEnteredMarks(int classId, int subjectId)
        {
            return _db.Marks.Count(m => m.SubjectId == subjectId && m.Student!.ClassId == classId);
        }
    }
}
