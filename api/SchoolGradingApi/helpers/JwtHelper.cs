using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using SchoolGradingApi.entities;

namespace SchoolGradingApi.helpers
{
    // Creates the JWT "login ticket" that the app sends with every request.
    public static class JwtHelper
    {
        public static (string token, DateTime expiresAt) CreateToken(AppUser user, IConfiguration config)
        {
            // Information stored inside the token (readable, but cannot be changed without the key)
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.FullName),
                new Claim(ClaimTypes.Role, user.Role),
                new Claim("loginId", user.LoginId)
            };

            // The secret key signs the token, so the server can trust it later
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var hours = config.GetValue<int>("Jwt:ExpiryHours", 8);
            var expiresAt = DateTime.UtcNow.AddHours(hours);

            var token = new JwtSecurityToken(
                issuer: config["Jwt:Issuer"],
                audience: config["Jwt:Audience"],
                claims: claims,
                expires: expiresAt,
                signingCredentials: credentials);

            return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
        }
    }
}
