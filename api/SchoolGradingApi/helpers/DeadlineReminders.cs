using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.database;
using SchoolGradingApi.entities;

namespace SchoolGradingApi.helpers
{
    // The automatic Result Date reminders for teachers.
    //
    // There is NO background job / cron: the free Azure App Service (F1) sleeps when nobody
    // uses it, and XAMPP only runs on the laptop. Instead the check runs "on demand" every time
    // a teacher opens their notifications (GET /api/notifications, the app asks every 30 s).
    //
    //   days left 7       -> "deadline_one_week"  (normal)
    //   days left 6 .. 3  -> "deadline_daily"     (normal)
    //   days left 2 .. 0  -> "deadline_urgent"    (IsUrgent = true, shown in red)
    //
    // Only teachers who STILL have unsubmitted subjects get one, at most once per day per type.
    public static class DeadlineReminders
    {
        public const string OneWeek = "deadline_one_week";
        public const string Daily = "deadline_daily";
        public const string Urgent = "deadline_urgent";
        public const string ClassTeacherReminder = "class_teacher_reminder";

        // The teacher's subjects that are not submitted yet. Deleted classes are left out
        // (the soft-delete query filter does it; the isDeleted check makes it easy to see).
        public static List<TeachingAssignment> PendingAssignments(AppDbContext db, int teacherId)
        {
            return db.TeachingAssignments
                .Include(a => a.Subject)
                .Include(a => a.SchoolClass)
                .Where(a => a.TeacherId == teacherId && a.SubmittedAt == null && !a.SchoolClass!.isDeleted)
                .OrderBy(a => a.SubjectId).ThenBy(a => a.ClassId)
                .ToList();
        }

        // "Physics (Class 8 - B, Class 9 - B), Chemistry (Class 9 - C)"
        public static string SubjectList(List<TeachingAssignment> pending)
        {
            var parts = pending
                .GroupBy(a => a.Subject!.Name)
                .Select(g => g.Key + " (" + string.Join(", ", g.Select(a => DtoMapper.ClassName(a.SchoolClass!))) + ")");
            return string.Join(", ", parts);
        }

        // Called by GET /api/notifications for a teacher. Adds today's reminder if one is due.
        public static void CreateIfDue(AppDbContext db, AppUser teacher)
        {
            if (teacher.Role != "teacher" || teacher.isDeleted) return;

            var resultDate = db.SchoolSettings.Where(s => s.Id == 1).Select(s => s.ResultDate).FirstOrDefault();
            if (resultDate == null) return;                         // the VP has not set a date

            int daysLeft = SchoolClock.DaysUntil(resultDate.Value);
            if (daysLeft < 0 || daysLeft > 7) return;               // too early, or already passed

            // Strict suppression: everything submitted = never bother this teacher
            var pending = PendingAssignments(db, teacher.Id);
            if (pending.Count == 0) return;

            string date = SchoolClock.Format(resultDate.Value);
            string subjects = SubjectList(pending);
            string type, title, message;
            bool isUrgent = false;

            if (daysLeft == 7)
            {
                type = OneWeek;
                title = "Result Date in 1 week";
                message = "Result is in 1 week (" + date + "). Please prepare and submit your pending marks (" + subjects + ").";
            }
            else if (daysLeft >= 3)
            {
                type = Daily;
                title = "Daily Reminder: " + daysLeft + " days left";
                message = "Daily Reminder: " + daysLeft + " days left until Result Date (" + date + "). Pending: " + subjects + ".";
            }
            else
            {
                type = Urgent;
                isUrgent = true;
                if (daysLeft == 0)
                {
                    title = "URGENT: Result Date is today";
                    message = "URGENT: The Result Date is today (" + date + ")! Submit your marks for " + subjects + " immediately.";
                }
                else
                {
                    string dayText = daysLeft == 1 ? "1 day" : daysLeft + " days";
                    title = "URGENT: Result Date in " + dayText;
                    message = "URGENT: Only " + dayText + " remaining until Result Date (" + date + ")! Submit your marks for " + subjects + " immediately.";
                }
            }

            // Deduplication: one reminder per (teacher, day, type). Refreshing never adds another.
            // A different type on the same day IS allowed (the VP moved the date to another range).
            var today = SchoolClock.Today;
            bool alreadySent = db.Notifications.Any(n =>
                n.RecipientUserId == teacher.Id && n.NotificationDate == today && n.Type == type);
            if (alreadySent) return;

            db.Notifications.Add(new Notification
            {
                RecipientUserId = teacher.Id,
                SenderUserId = null,                  // automatic = sent by the system
                Type = type,
                Title = title,
                Message = message,
                IsUrgent = isUrgent,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                NotificationDate = today,
                AssignmentId = null
            });
            db.SaveChanges();
        }

        // Called after a teacher's FINAL submit: if nothing is pending any more, their unread
        // automatic deadline reminders are marked as read, so they stop being bothered at once.
        public static void StopIfAllSubmitted(AppDbContext db, int teacherId)
        {
            if (PendingAssignments(db, teacherId).Count > 0) return;

            var unread = db.Notifications
                .Where(n => n.RecipientUserId == teacherId && !n.IsRead &&
                            (n.Type == OneWeek || n.Type == Daily || n.Type == Urgent))
                .ToList();
            foreach (var n in unread)
            {
                n.IsRead = true;
            }
            db.SaveChanges();
        }

        // The teacher submitted this subject + class: the Class Teacher's reminders about it
        // ("Marks Reminder - Class 8 - B (Physics)") are done, so they are marked as read.
        public static void ClearClassTeacherReminders(AppDbContext db, int teacherId, int assignmentId)
        {
            var unread = db.Notifications
                .Where(n => n.RecipientUserId == teacherId && !n.IsRead &&
                            n.Type == ClassTeacherReminder && n.AssignmentId == assignmentId)
                .ToList();
            foreach (var n in unread)
            {
                n.IsRead = true;
            }
            db.SaveChanges();
        }
    }
}
