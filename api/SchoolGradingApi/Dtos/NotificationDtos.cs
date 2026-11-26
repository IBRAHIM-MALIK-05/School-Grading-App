namespace SchoolGradingApi.Dtos
{
    // GET /api/settings/result-date  (response)
    public class ResultDateDto
    {
        public DateOnly? ResultDate { get; set; }      // null = not set yet
        public int? DaysRemaining { get; set; }        // 0 = today, negative = already passed
        public DateOnly Today { get; set; }            // the school's "today" (Pakistan time)
        public string? UpdatedByName { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    // PUT /api/settings/result-date  (request)  { "resultDate": "2026-12-03" }  or  { "resultDate": null }
    public class SetResultDateDto
    {
        public DateOnly? ResultDate { get; set; }
    }

    // POST /api/notifications/remind  (request)
    public class RemindDto
    {
        public int AssignmentId { get; set; }          // which subject + class (teaching_assignments.Id)
        public string? Message { get; set; }           // optional short note from the Class Teacher
    }

    // One notification in the bell
    public class NotificationDto
    {
        public int Id { get; set; }
        public string Type { get; set; } = "";
        public string Title { get; set; } = "";
        public string Message { get; set; } = "";
        public bool IsUrgent { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateOnly NotificationDate { get; set; }
        public string? SenderName { get; set; }        // null = automatic reminder
        public int? AssignmentId { get; set; }
    }

    // GET /api/notifications  (response)
    public class NotificationListDto
    {
        public int UnreadCount { get; set; }
        public DateOnly? ResultDate { get; set; }
        public int? DaysRemaining { get; set; }
        public List<NotificationDto> Items { get; set; } = new List<NotificationDto>();
    }
}
