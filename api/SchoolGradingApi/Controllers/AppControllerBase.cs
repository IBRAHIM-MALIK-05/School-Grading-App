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

        // ----- "Subject -> Class" pairs (Create Account / Edit User) -----

        // Checks the pairs BEFORE anything is saved: no duplicates, subjects + classes exist,
        // and a subject is not ADDED to a class whose results are already published.
        protected IActionResult? CheckSubjectClassPairs(List<SubjectClassDto> pairs)
        {
            if (pairs.Select(p => (p.SubjectId, p.ClassId)).Distinct().Count() != pairs.Count)
                return Error(400, "The same subject + class was picked twice.");

            var subjectIds = pairs.Select(p => p.SubjectId).Distinct().ToList();
            var classIds = pairs.Select(p => p.ClassId).Distinct().ToList();
            if (_db.Subjects.Count(s => subjectIds.Contains(s.Id)) != subjectIds.Count)
                return Error(400, "One or more subjects do not exist.");
            var classes = _db.Classes.Where(c => classIds.Contains(c.Id)).ToList();
            if (classes.Count != classIds.Count)
                return Error(400, "One or more classes do not exist.");

            foreach (var p in pairs)
            {
                var schoolClass = classes.First(c => c.Id == p.ClassId);
                bool alreadyTaught = _db.TeachingAssignments.Any(a => a.ClassId == p.ClassId && a.SubjectId == p.SubjectId);
                if (!alreadyTaught && schoolClass.ResultsPublishedAt != null)
                    return Error(409, "Results of " + DtoMapper.ClassName(schoolClass) +
                                      " are published. Unpublish first to add a subject there.");
            }
            return null;
        }

        // Gives every pair to this teacher (call CheckSubjectClassPairs first):
        //  - someone already teaches it there -> it moves to this teacher (marks + submitted status kept)
        //  - nobody teaches it there yet      -> the subject is added to that class
        protected void GiveSubjectClasses(int teacherId, List<SubjectClassDto> pairs)
        {
            foreach (var p in pairs)
            {
                var existing = _db.TeachingAssignments.FirstOrDefault(a => a.ClassId == p.ClassId && a.SubjectId == p.SubjectId);
                if (existing != null)
                {
                    existing.TeacherId = teacherId;
                }
                else
                {
                    _db.TeachingAssignments.Add(new TeachingAssignment
                    {
                        ClassId = p.ClassId, SubjectId = p.SubjectId, TeacherId = teacherId
                    });
                }
            }
        }

        // Name + Gmail rules shared by Create Account and Edit User (null = OK)
        protected IActionResult? CheckNameAndEmail(string fullName, string email)
        {
            if (fullName == "")
                return Error(400, "Full name is required.");
            if (fullName.Length > 100)
                return Error(400, "Full name can be at most 100 characters.");
            if (email.Length > 150 || !System.Text.RegularExpressions.Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
                return Error(400, "Please enter a valid email address.");
            return null;
        }
    }
}
