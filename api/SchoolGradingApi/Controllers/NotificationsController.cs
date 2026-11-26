using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;
using SchoolGradingApi.helpers;

namespace SchoolGradingApi.Controllers
{
    // The Notification Bell: our own notifications stored in MySQL (no Firebase).
    // The app asks for them every 30 seconds and shows a popup for new ones
    // (flutter_local_notifications), so the server never has to "push" anything.
    [Route("api/notifications")]
    public class NotificationsController : AppControllerBase
    {
        // A Class Teacher cannot send the same subject another reminder while the last one
        // is still unread and younger than this (stops spamming).
        private const int ReminderCooldownMinutes = 60;

        public NotificationsController(AppDbContext db) : base(db)
        {
        }

        // My notifications. Reminders about a subject of a soft-deleted class are hidden.
        private IQueryable<Notification> VisibleNotifications(int userId)
        {
            var deletedClassAssignmentIds = _db.TeachingAssignments
                .IgnoreQueryFilters()
                .Where(a => a.SchoolClass!.isDeleted)
                .Select(a => a.Id)
                .ToList();

            return _db.Notifications.Where(n => n.RecipientUserId == userId &&
                (n.AssignmentId == null || !deletedClassAssignmentIds.Contains(n.AssignmentId.Value)));
        }

        // 34) GET /api/notifications  -> my notifications, newest first.
        //     For a teacher it first runs the automatic Result Date check (no cron job needed).
        [HttpGet]
        public IActionResult GetMine()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            DeadlineReminders.CreateIfDue(_db, me);

            var items = VisibleNotifications(me.Id)
                .Include(n => n.SenderUser)
                .OrderByDescending(n => n.CreatedAt).ThenByDescending(n => n.Id)
                .Take(50)
                .ToList();

            var resultDate = _db.SchoolSettings.Where(s => s.Id == 1).Select(s => s.ResultDate).FirstOrDefault();

            return Ok(new NotificationListDto
            {
                UnreadCount = VisibleNotifications(me.Id).Count(n => !n.IsRead),
                ResultDate = resultDate,
                DaysRemaining = resultDate == null ? null : SchoolClock.DaysUntil(resultDate.Value),
                Items = items.Select(n => new NotificationDto
                {
                    Id = n.Id,
                    Type = n.Type,
                    Title = n.Title,
                    Message = n.Message,
                    IsUrgent = n.IsUrgent,
                    IsRead = n.IsRead,
                    CreatedAt = n.CreatedAt,
                    NotificationDate = n.NotificationDate,
                    SenderName = n.SenderUser?.FullName,
                    AssignmentId = n.AssignmentId
                }).ToList()
            });
        }

        // 35) POST /api/notifications/remind  -> the Class Teacher nudges ONE subject teacher
        [HttpPost("remind")]
        public IActionResult Remind(RemindDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            // Include(SchoolClass) also hides subjects of soft-deleted classes (query filter)
            var assignment = _db.TeachingAssignments
                .Include(a => a.SchoolClass)
                .Include(a => a.Subject)
                .Include(a => a.Teacher)
                .FirstOrDefault(a => a.Id == dto.AssignmentId);
            if (assignment == null || assignment.SchoolClass == null) return Error(404, "Assignment not found.");

            var schoolClass = assignment.SchoolClass;
            var subject = assignment.Subject!;
            string className = DtoMapper.ClassName(schoolClass);

            // Only the Class Teacher of THIS class (not its subject teachers, other teachers, VP or Admin)
            if (me.Role != "teacher" || schoolClass.ClassTeacherId != me.Id)
                return Error(403, "Only the Class Teacher of " + className + " can send reminders for its subjects.");

            if (assignment.TeacherId == me.Id)
                return Error(400, subject.Name + " in " + className + " is your own subject.");

            if (assignment.SubmittedAt != null)
                return Error(409, "Marks for " + subject.Name + " have already been submitted.");

            var teacher = assignment.Teacher;   // null if that teacher was soft-deleted
            if (teacher == null)
                return Error(409, "The teacher of " + subject.Name + " in " + className + " is no longer active.");

            var note = (dto.Message ?? "").Trim();
            if (note.Length > 200)
                return Error(400, "The note can be at most 200 characters.");

            // Anti-spam: the previous reminder for this subject is still unread and recent
            var since = DateTime.UtcNow.AddMinutes(-ReminderCooldownMinutes);
            bool stillWaiting = _db.Notifications.Any(n => n.AssignmentId == assignment.Id &&
                n.Type == DeadlineReminders.ClassTeacherReminder && !n.IsRead && n.CreatedAt >= since);
            if (stillWaiting)
                return Error(429, "A reminder for " + subject.Name + " was sent less than " + ReminderCooldownMinutes +
                                  " minutes ago and " + teacher.FullName + " has not read it yet.");

            string message = me.FullName + ", the Class Teacher of " + className + ", is waiting for your " +
                             subject.Name + " marks for " + className + ".";
            if (note != "")
                message += " Note: " + note;

            var notification = new Notification
            {
                RecipientUserId = teacher.Id,
                SenderUserId = me.Id,
                Type = DeadlineReminders.ClassTeacherReminder,
                Title = "Marks Reminder — " + className + " (" + subject.Name + ")",
                Message = message,
                IsUrgent = false,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                NotificationDate = SchoolClock.Today,
                AssignmentId = assignment.Id
            };
            _db.Notifications.Add(notification);
            _db.SaveChanges();

            return StatusCode(201, new
            {
                id = notification.Id,
                message = "Reminder sent to " + teacher.FullName + " for " + subject.Name + "."
            });
        }

        // 36) PUT /api/notifications/{id}/read  -> mark ONE of my notifications as read
        [HttpPut("{id:int}/read")]
        public IActionResult MarkRead(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            // Someone else's notification looks exactly like a missing one (404)
            var notification = _db.Notifications.FirstOrDefault(n => n.Id == id && n.RecipientUserId == me.Id);
            if (notification == null) return Error(404, "Notification not found.");

            notification.IsRead = true;
            _db.SaveChanges();
            return Ok(new { message = "Marked as read.", unreadCount = VisibleNotifications(me.Id).Count(n => !n.IsRead) });
        }

        // 37) PUT /api/notifications/read-all  -> mark ALL my notifications as read
        [HttpPut("read-all")]
        public IActionResult MarkAllRead()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();

            var unread = _db.Notifications.Where(n => n.RecipientUserId == me.Id && !n.IsRead).ToList();
            foreach (var n in unread)
            {
                n.IsRead = true;
            }
            _db.SaveChanges();
            return Ok(new { message = unread.Count + " notification(s) marked as read.", unreadCount = 0 });
        }
    }
}
