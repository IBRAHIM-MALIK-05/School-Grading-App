namespace SchoolGradingApi.helpers
{
    public static class GradeHelper
    {
        public const string SchoolName = "SLS Montessori School and College";

        // Percentage -> grade (same scale used on the result card)
        public static string GetGrade(double percentage)
        {
            if (percentage >= 80) return "A+";
            if (percentage >= 70) return "A";
            if (percentage >= 60) return "B";
            if (percentage >= 50) return "C";
            if (percentage >= 40) return "D";
            return "F";
        }
    }
}
