namespace SchoolGradingApi.helpers
{
    // "What day is it at the school?"
    // Azure servers run on UTC, but the school is in Pakistan (UTC+5, no daylight saving).
    // Using UTC alone would switch to "tomorrow" at 7 pm in Pakistan, so the days left
    // until the Result Date would be wrong in the evening.
    public static class SchoolClock
    {
        public const int PakistanUtcOffsetHours = 5;

        public static DateOnly Today
        {
            get { return DateOnly.FromDateTime(DateTime.UtcNow.AddHours(PakistanUtcOffsetHours)); }
        }

        // Days from today until the given date (0 = today, negative = already passed)
        public static int DaysUntil(DateOnly date)
        {
            return date.DayNumber - Today.DayNumber;
        }

        // "3 Dec 2026"
        public static string Format(DateOnly date)
        {
            return date.ToString("d MMM yyyy", System.Globalization.CultureInfo.InvariantCulture);
        }
    }
}
