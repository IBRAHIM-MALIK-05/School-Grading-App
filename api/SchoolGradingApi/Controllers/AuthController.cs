using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    [Route("api/auth")]
    public class AuthController : AppControllerBase
    {
        private readonly IConfiguration _config;

        public AuthController(AppDbContext db, IConfiguration config) : base(db)
        {
            _config = config;
        }

        // 1) POST /api/auth/login  -> checks the password and returns a JWT token
        [AllowAnonymous]
        [HttpPost("login")]
        public IActionResult Login(LoginDto dto)
        {
            var loginId = dto.LoginId.Trim().ToLower();
            var user = _db.Users.FirstOrDefault(u => u.LoginId == loginId);

            // Same message for "no such user" and "wrong password" (safer)
            if (user == null || !PasswordHelper.Verify(dto.Password, user.PasswordHash))
            {
                return Error(401, "Invalid Login ID or password.");
            }

            // Admin Login vs Teacher / VP Login (only when the app says which screen was used).
            // Checked AFTER the password, so it never reveals the role of an account to a stranger.
            var portal = dto.Portal?.Trim().ToLower();
            if (portal == "admin" && user.Role != "admin")
                return Error(403, "This portal is for Admins only. Please use Staff Login.");
            if (portal == "staff" && user.Role == "admin")
                return Error(403, "This is an Admin account. Please use \"Login as Admin\".");
            if (portal != null && portal != "admin" && portal != "staff")
                return Error(400, "Portal must be \"admin\" or \"staff\".");

            var (token, expiresAt) = JwtHelper.CreateToken(user, _config);
            return Ok(new LoginResponseDto
            {
                Token = token,
                ExpiresAt = expiresAt,
                User = MakeUserDto(user)
            });
        }

        // 2) POST /api/auth/change-password  -> also used for the forced first-login change
        [HttpPost("change-password")]
        public IActionResult ChangePassword(ChangePasswordDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            // (no MustChangePassword check here: this is how they fix it)

            if (!PasswordHelper.Verify(dto.CurrentPassword, me.PasswordHash))
            {
                return Error(400, "Current password is incorrect.");
            }

            var problem = PasswordHelper.CheckNewPassword(me, dto.CurrentPassword, dto.NewPassword);
            if (problem != null)
            {
                return Error(400, problem);
            }

            me.PasswordHash = PasswordHelper.Hash(dto.NewPassword);
            me.MustChangePassword = false;
            _db.SaveChanges();

            return Ok(MakeUserDto(me));
        }

        // 3) POST /api/auth/register  -> Admin creates a Teacher or Principal/VP account
        [HttpPost("register")]
        public IActionResult Register(AddUserDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can create accounts.");

            // ----- check the input -----
            var fullName = dto.FullName.Trim();
            var email = dto.ContactEmail.Trim();
            var pairs = dto.Assignments ?? new List<SubjectClassDto>();
            var nameProblem = CheckNameAndEmail(fullName, email);
            if (nameProblem != null) return nameProblem;
            if (dto.Role != "teacher" && dto.Role != "vp")
                return Error(400, "Role must be 'teacher' or 'vp'.");
            if (dto.Role != "teacher" && (dto.ClassTeacherOfClassId != null || dto.AssignmentIds.Count > 0 || pairs.Count > 0))
                return Error(400, "Only a Teacher can be a Class Teacher or teach subjects.");
            var pairProblem = CheckSubjectClassPairs(pairs);
            if (pairProblem != null) return pairProblem;

            SchoolClass? classToLead = null;
            if (dto.ClassTeacherOfClassId != null)
            {
                classToLead = _db.Classes.FirstOrDefault(c => c.Id == dto.ClassTeacherOfClassId);
                if (classToLead == null)
                    return Error(404, "Class not found.");
                if (classToLead.ClassTeacherId != null)
                    return Error(409, DtoMapper.ClassName(classToLead) + " already has a Class Teacher.");
            }

            var assignments = _db.TeachingAssignments.Where(a => dto.AssignmentIds.Contains(a.Id)).ToList();
            if (assignments.Count != dto.AssignmentIds.Distinct().Count())
                return Error(400, "One or more selected subjects do not exist.");

            // ----- create the user -----
            // One transaction: if giving the class / subjects fails, the new user is rolled back too
            // (no half-created account without its duties).
            using var transaction = _db.Database.BeginTransaction();
            // IgnoreQueryFilters: soft-deleted users still own their Login ID (UNIQUE in MySQL)
            var existingLoginIds = _db.Users.IgnoreQueryFilters().Select(u => u.LoginId).ToList();
            var temporaryPassword = PasswordHelper.GenerateTemporaryPassword();

            var user = new AppUser
            {
                FullName = fullName,
                LoginId = PasswordHelper.GenerateLoginId(fullName, existingLoginIds),
                ContactEmail = email,
                PasswordHash = PasswordHelper.Hash(temporaryPassword),
                Role = dto.Role,
                MustChangePassword = true,          // must change at first login
                CreatedAt = DateTime.UtcNow
            };
            _db.Users.Add(user);
            _db.SaveChanges();                      // now user.Id exists

            // Make them class teacher + give them their subjects (replaces the old teacher)
            if (classToLead != null)
            {
                classToLead.ClassTeacherId = user.Id;
            }
            foreach (var assignment in assignments)
            {
                assignment.TeacherId = user.Id;
            }
            GiveSubjectClasses(user.Id, pairs);    // "Mathematics -> Class 8 - A" picks
            _db.SaveChanges();
            transaction.Commit();                   // both saves succeed together (or neither)

            // 201 Created + the details the Admin will share (shown only once)
            return StatusCode(201, new CredentialsDto
            {
                FullName = user.FullName,
                LoginId = user.LoginId,
                TemporaryPassword = temporaryPassword,
                ContactEmail = user.ContactEmail
            });
        }

        // 4) POST /api/auth/reset-password/{userId}  -> Admin resets a forgotten password
        [HttpPost("reset-password/{userId}")]
        public IActionResult ResetPassword(int userId)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can reset passwords.");

            var user = _db.Users.FirstOrDefault(u => u.Id == userId);
            if (user == null) return Error(404, "User not found.");
            if (user.Id == me.Id) return Error(400, "Use Change Password for your own account.");

            var temporaryPassword = PasswordHelper.GenerateTemporaryPassword();
            user.PasswordHash = PasswordHelper.Hash(temporaryPassword);
            user.MustChangePassword = true;
            _db.SaveChanges();

            return Ok(new CredentialsDto
            {
                FullName = user.FullName,
                LoginId = user.LoginId,
                TemporaryPassword = temporaryPassword,
                ContactEmail = user.ContactEmail
            });
        }
    }
}
