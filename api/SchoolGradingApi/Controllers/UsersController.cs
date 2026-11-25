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

        // ================= Soft delete / hard delete (names from Assignment 2) =================

        // 24) DELETE /api/users/SoftDeleteById?id=7  -> Admin "deletes" a Teacher or Principal/VP.
        //     Soft delete: isDeleted = true, the row stays in MySQL. The user disappears from every
        //     list and picker, cannot log in, and their old token stops working (401).
        [HttpDelete("SoftDeleteById")]
        public IActionResult SoftDeleteById(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can delete accounts.");
            if (id == me.Id) return Error(400, "You cannot delete your own account.");

            var userRecord = _db.Users.Where(x => x.Id == id).FirstOrDefault();
            if (userRecord == null) return Error(404, "User not found.");
            if (userRecord.Role == "admin") return Error(400, "The Admin account cannot be deleted.");

            // A teacher who still has work cannot just disappear: hand it over first
            var ledClass = _db.Classes.FirstOrDefault(c => c.ClassTeacherId == id);
            if (ledClass != null)
                return Error(409, userRecord.FullName + " is the Class Teacher of " + DtoMapper.ClassName(ledClass) +
                                  ". Pick another Class Teacher for it first (Classes tab).");
            var subjects = _db.TeachingAssignments
                .Include(a => a.Subject).Include(a => a.SchoolClass)   // only classes that are not deleted
                .Where(a => a.TeacherId == id)
                .ToList();
            if (subjects.Count > 0)
                return Error(409, userRecord.FullName + " still teaches " + subjects.Count + " subject(s), e.g. " +
                                  subjects[0].Subject!.Name + " in " + DtoMapper.ClassName(subjects[0].SchoolClass!) +
                                  ". Give them to other teachers first (Classes tab).");

            userRecord.isDeleted = true;
            _db.Users.Update(userRecord);
            _db.SaveChanges();
            return Ok(new { message = userRecord.FullName + " was deleted." });
        }

        // 25) GET /api/users/GetDeleted  -> backend maintainer (Swagger): every soft-deleted account
        [HttpGet("GetDeleted")]
        public IActionResult GetDeleted()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can see deleted accounts.");

            var users = _db.Users.IgnoreQueryFilters()      // include the deleted rows
                .Where(x => x.isDeleted)
                .OrderBy(x => x.Id)
                .ToList()
                .Select(u => DtoMapper.ToUserDto(u, null))
                .ToList();
            return Ok(users);
        }

        // 26) PUT /api/users/RestoreById?id=7  -> backend maintainer (Swagger): undo a soft delete
        [HttpPut("RestoreById")]
        public IActionResult RestoreById(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can restore accounts.");

            var userRecord = _db.Users.IgnoreQueryFilters().Where(x => x.Id == id).FirstOrDefault();
            if (userRecord == null) return Error(404, "User not found.");
            if (!userRecord.isDeleted) return Error(400, userRecord.FullName + " is not deleted.");

            userRecord.isDeleted = false;
            _db.Users.Update(userRecord);
            _db.SaveChanges();
            return Ok(new { message = userRecord.FullName + " was restored and can log in again." });
        }

        // 27) DELETE /api/users/HardDeleteById?id=7  -> backend maintainer ONLY (Swagger, not in the app):
        //     removes the row from MySQL for ever. Refused (409) while marks or other rows still
        //     point to this user, so results and history are never lost.
        [HttpDelete("HardDeleteById")]
        public IActionResult HardDeleteById(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can permanently delete accounts.");
            if (id == me.Id) return Error(400, "You cannot delete your own account.");

            var userRecord = _db.Users.IgnoreQueryFilters().Where(x => x.Id == id).FirstOrDefault();
            if (userRecord == null) return Error(404, "User not found.");
            if (userRecord.Role == "admin") return Error(400, "The Admin account cannot be deleted.");

            // Foreign keys that point to this user (also in deleted classes)
            int subjects = _db.TeachingAssignments.Count(a => a.TeacherId == id);
            int marks = _db.Marks.Count(m => m.EnteredById == id);
            int removals = _db.StudentRemovals.Count(r => r.RemovedById == id);
            if (subjects + marks + removals > 0)
                return Error(409, userRecord.FullName + " cannot be deleted permanently: still linked to " +
                                  subjects + " subject(s) in classes, " + marks + " mark(s) and " +
                                  removals + " student-removal notice(s). Keep the account soft-deleted instead.");

            // A Class Teacher link is cleared by MySQL itself (classes.ClassTeacherId ON DELETE SET NULL)
            _db.Users.Remove(userRecord);
            try
            {
                _db.SaveChanges();
            }
            catch (DbUpdateException)
            {
                return Error(409, userRecord.FullName + " is still used by other rows, so it cannot be deleted permanently.");
            }
            return Ok(new { message = userRecord.FullName + " was permanently deleted." });
        }
    }
}
