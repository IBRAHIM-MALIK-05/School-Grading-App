using System.Security.Cryptography;
using System.Text.RegularExpressions;
using SchoolGradingApi.entities;

namespace SchoolGradingApi.helpers
{
    // Everything about passwords and Login IDs in one place.
    public static class PasswordHelper
    {
        // BCrypt = slow, salted hash. Same password -> different hash every time,
        // and it cannot be turned back into the password.
        public static string Hash(string password)
        {
            return BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);
        }

        public static bool Verify(string password, string hash)
        {
            return BCrypt.Net.BCrypt.Verify(password, hash);
        }

        // 10 random characters, no look-alike characters (0/O, 1/l/I)
        public static string GenerateTemporaryPassword()
        {
            const string letters = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz";
            const string digits = "23456789";
            const string all = letters + digits;

            while (true)
            {
                var chars = new char[10];
                for (int i = 0; i < chars.Length; i++)
                {
                    chars[i] = all[RandomNumberGenerator.GetInt32(all.Length)];   // secure random
                }
                var password = new string(chars);
                if (password.Any(char.IsLetter) && password.Any(char.IsDigit))
                {
                    return password;
                }
            }
        }

        // Rules for a NEW password. Returns an error message, or null if it is OK.
        public static string? CheckNewPassword(AppUser user, string currentPassword, string newPassword)
        {
            if (newPassword.Length < 8)
                return "Password must be at least 8 characters.";
            if (!newPassword.Any(char.IsLetter) || !newPassword.Any(char.IsDigit))
                return "Password must contain at least one letter and one number.";
            if (newPassword.Equals(user.LoginId, StringComparison.OrdinalIgnoreCase))
                return "Password cannot be the same as your Login ID.";
            if (newPassword == currentPassword)
                return "New password must be different from the current one.";
            return null;
        }

        // "Teacher Ali Raza" -> "ali@school.com"  (ali2@school.com if taken, ...)
        public static string GenerateLoginId(string fullName, List<string> existingLoginIds)
        {
            string[] titles = { "teacher", "mr", "mrs", "ms", "miss", "dr", "sir", "vp", "principal" };

            var firstName = fullName.ToLower()
                .Split(' ', StringSplitOptions.RemoveEmptyEntries)
                .Select(word => Regex.Replace(word, "[^a-z]", ""))
                .FirstOrDefault(word => word != "" && !titles.Contains(word));

            if (string.IsNullOrEmpty(firstName))
                firstName = "user";

            var loginId = firstName + "@school.com";
            int number = 2;
            while (existingLoginIds.Contains(loginId))
            {
                loginId = firstName + number + "@school.com";
                number++;
            }
            return loginId;
        }
    }
}
