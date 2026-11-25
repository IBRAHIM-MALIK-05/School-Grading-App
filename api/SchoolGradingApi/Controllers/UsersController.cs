using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    [Route("api/users")]
    public class UsersController : AppControllerBase
    {
        public UsersController(AppDbContext db) : base(db)
        {
        }

        // 5) GET /api/users  -> Admin sees every account
        [HttpGet]
        public IActionResult GetAll()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can see all users.");

            var classes = _db.Classes.ToList();
            var users = _db.Users
                .OrderBy(u => u.Id)
                .ToList()
                .Select(u => DtoMapper.ToUserDto(u, classes.FirstOrDefault(c => c.ClassTeacherId == u.Id)))
                .ToList();

            return Ok(users);
        }

        // 19) PUT /api/users/{id}  -> Admin edits a Teacher or Principal/VP
        //     Name, Gmail, Class Teacher role and "Subject -> Class" duties. The Login ID never changes.
        //     Marks are never lost: a subject that already has marks cannot be taken away here
        //     (give it to another teacher in Manage Classes instead).
        [HttpPut("{id}")]
        public IActionResult Edit(int id, EditUserDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can edit accounts.");

            var user = _db.Users.FirstOrDefault(u => u.Id == id);
            if (user == null) return Error(404, "User not found.");
            if (user.Role == "admin") return Error(400, "The Admin account cannot be edited here.");

            var fullName = (dto.FullName ?? "").Trim();
            var email = (dto.ContactEmail ?? "").Trim();
            var wanted = dto.Assignments ?? new List<SubjectClassDto>();
            var problem = CheckNameAndEmail(fullName, email);
            if (problem != null) return problem;
            if (user.Role != "teacher" && (dto.ClassTeacherOfClassId != null || wanted.Count > 0))
                return Error(400, "Only a Teacher can be a Class Teacher or teach subjects.");
            problem = CheckSubjectClassPairs(wanted);
            if (problem != null) return problem;

            // ----- Class Teacher of -----
            var currentClass = _db.Classes.FirstOrDefault(c => c.ClassTeacherId == user.Id);
            SchoolClass? newClass = null;
            if (dto.ClassTeacherOfClassId != null && dto.ClassTeacherOfClassId != currentClass?.Id)
            {
                newClass = _db.Classes.FirstOrDefault(c => c.Id == dto.ClassTeacherOfClassId);
                if (newClass == null) return Error(404, "Class not found.");
                if (newClass.ClassTeacherId != null)
                    return Error(409, DtoMapper.ClassName(newClass) + " already has a Class Teacher.");
            }

            // ----- subjects taken AWAY from this teacher -----
            var current = _db.TeachingAssignments
                .Include(a => a.Subject).Include(a => a.SchoolClass)
                .Where(a => a.TeacherId == user.Id)
                .ToList();
            var removed = current.Where(a => !wanted.Any(w => w.SubjectId == a.SubjectId && w.ClassId == a.ClassId)).ToList();
            foreach (var a in removed)
            {
                string what = a.Subject!.Name + " in " + DtoMapper.ClassName(a.SchoolClass!);
                if (CountEnteredMarks(a.ClassId, a.SubjectId) > 0)
                    return Error(409, what + " already has marks, so it cannot be taken away from " + user.FullName +
                                      ". Give it to another teacher in Manage Classes instead.");
                if (a.SchoolClass!.ResultsPublishedAt != null)
                    return Error(409, "Results of " + DtoMapper.ClassName(a.SchoolClass) + " are published. Unpublish first.");
            }

            // ----- save everything in ONE transaction -----
            user.FullName = fullName;
            user.ContactEmail = email;
            if (dto.ClassTeacherOfClassId == null && currentClass != null)
                currentClass.ClassTeacherId = null;             // no longer a Class Teacher
            if (newClass != null)
            {
                if (currentClass != null) currentClass.ClassTeacherId = null;
                newClass.ClassTeacherId = user.Id;
            }
            _db.TeachingAssignments.RemoveRange(removed);       // no marks -> the subject leaves that class
            GiveSubjectClasses(user.Id, wanted);
            _db.SaveChanges();

            return Ok(MakeUserDto(user));
        }
    }
}
