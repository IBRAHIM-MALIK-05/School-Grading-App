using Microsoft.AspNetCore.Mvc;
using SchoolGradingApi.database;
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
    }
}
