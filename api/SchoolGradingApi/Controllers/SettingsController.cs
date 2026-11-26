using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    // School-wide settings. For now: the Result Date (set by the Principal / VP only).
    [Route("api/settings")]
    public class SettingsController : AppControllerBase
    {
        public SettingsController(AppDbContext db) : base(db)
        {
        }

        // The single settings row (Id = 1). Created if it is missing, so the API never crashes.
        private SchoolSettings LoadSettings()
        {
            var settings = _db.SchoolSettings.Include(s => s.UpdatedByUser).FirstOrDefault(s => s.Id == 1);
            if (settings == null)
            {
                settings = new SchoolSettings { Id = 1 };
                _db.SchoolSettings.Add(settings);
                _db.SaveChanges();
            }
            return settings;
        }

        private static ResultDateDto ToDto(SchoolSettings settings)
        {
            return new ResultDateDto
            {
                ResultDate = settings.ResultDate,
                DaysRemaining = settings.ResultDate == null ? null : SchoolClock.DaysUntil(settings.ResultDate.Value),
                Today = SchoolClock.Today,
                UpdatedByName = settings.UpdatedByUser?.FullName,
                UpdatedAt = settings.UpdatedAt
            };
        }

        // 32) GET /api/settings/result-date  -> everyone who is logged in can see it
        [HttpGet("result-date")]
        public IActionResult GetResultDate()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            return Ok(ToDto(LoadSettings()));
        }

        // 33) PUT /api/settings/result-date  -> ONLY the Principal / VP sets, changes or clears it
        [HttpPut("result-date")]
        public IActionResult SetResultDate(SetResultDateDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "vp") return Error(403, "Only the Principal / VP can set the Result Date.");

            if (dto.ResultDate != null && dto.ResultDate.Value < SchoolClock.Today)
                return Error(400, "The Result Date cannot be in the past.");

            var settings = LoadSettings();
            settings.ResultDate = dto.ResultDate;
            settings.UpdatedByUserId = me.Id;
            settings.UpdatedByUser = me;
            settings.UpdatedAt = DateTime.UtcNow;
            _db.SaveChanges();

            return Ok(ToDto(settings));
        }
    }
}
