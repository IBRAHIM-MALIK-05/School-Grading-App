using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using SchoolGradingApi.database;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

// Swagger + an "Authorize" button where we paste the JWT token
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "School Grading API", Version = "v1" });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Login with POST /api/auth/login, then paste the token here."
    });
    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = new List<string>()
    });
});

// MySQL (XAMPP locally, Azure later) - only the connection string changes
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySQL(builder.Configuration.GetConnectionString("DefaultConnection")!)
           .AddInterceptors(new MariaDbFix()));   // XAMPP MariaDB fix, see database/MariaDbFix.cs

// JWT login: every request must carry a token signed with our secret key
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });
builder.Services.AddAuthorization();

// CORS: allow the Flutter web app (another origin) to call this API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

// Swagger is also kept on Azure so the live API can be shown in class
app.UseSwagger();
app.UseSwaggerUI();

// (No HTTPS redirect: the Flutter app and Android emulator call http://localhost locally;
//  Azure App Service gives HTTPS automatically.)

app.UseCors("AllowFlutterApp");

app.UseAuthentication();   // who are you? (reads the JWT)
app.UseAuthorization();    // are you allowed?

app.MapControllers();

app.Run();
