namespace SchoolGradingApi.entities
{
    // Table: notifications
    // One message in a user's Notification Bell. Two kinds:
    //   "class_teacher_reminder"   - a Class Teacher nudges ONE subject teacher (SenderUserId = the Class Teacher)
    //   "deadline_one_week" / "deadline_daily" / "deadline_urgent"
    //                              - automatic Result Date reminders (SenderUserId = null = the system)
    public class Notification
    {
        public int Id { get; set; }

        // Foreign key -> users.Id (who gets it)
        public int RecipientUserId { get; set; }
        public AppUser? RecipientUser { get; set; }

        // Foreign key -> users.Id (who sent it). null = automatic system reminder
        public int? SenderUserId { get; set; }
        public AppUser? SenderUser { get; set; }

        public string Type { get; set; } = "";
        public string Title { get; set; } = "";
        public string Message { get; set; } = "";

        // true = the red "2 days or less" alert
        public bool IsUrgent { get; set; }

        public bool IsRead { get; set; }

        public DateTime CreatedAt { get; set; }

        // The school day it was made for. Automatic reminders are created at most once
        // per (recipient, day, type), so refreshing the app never makes duplicates.
        public DateOnly NotificationDate { get; set; }

        // Foreign key -> teaching_assignments.Id (which subject + class a reminder is about)
        public int? AssignmentId { get; set; }
        public TeachingAssignment? Assignment { get; set; }
    }
}
