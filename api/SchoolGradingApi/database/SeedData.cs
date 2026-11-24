using Microsoft.EntityFrameworkCore;
using SchoolGradingApi.entities;

namespace SchoolGradingApi.database
{
    // Demo data inserted by the migration (same data the Flutter mock "DummyDB" used),
    // so all old demo logins keep working. Password for every demo user: 123
    public static class SeedData
    {
        // Fixed dates so the migration is the same every time it is generated
        private static readonly DateTime Created = new DateTime(2026, 11, 20, 9, 0, 0);
        private static readonly DateTime Submitted = new DateTime(2026, 11, 20, 10, 30, 0);

        public static void Add(ModelBuilder modelBuilder)
        {
            // ---------------- users ----------------
            // PasswordHash = BCrypt hash of "123" (each one has its own random salt)
            modelBuilder.Entity<AppUser>().HasData(
                new AppUser { Id = 1, FullName = "School Admin", LoginId = "admin@school.com", Role = "admin", CreatedAt = Created,
                    PasswordHash = "$2a$11$c6gJO2BSfKjGK2cigDfJZOnxFT6ddgxsJnwSCAYt2VHHGDpaTrTk2" },
                new AppUser { Id = 2, FullName = "VP Sarah", LoginId = "vp@school.com", Role = "vp", CreatedAt = Created,
                    PasswordHash = "$2a$11$knbs2jFie66WoIHXYKVkOetGaC0bkXmUDHQmjGEIDfPLqP2D9rREq" },
                new AppUser { Id = 3, FullName = "Teacher Sania", LoginId = "sania@school.com", Role = "teacher", CreatedAt = Created,
                    PasswordHash = "$2a$11$zUYQ3hSJRte1VA7nbAlzwO0h9woXmWqkT0LuUm2mVhfYVeCCWoWfi" },
                new AppUser { Id = 4, FullName = "Teacher Ahsan", LoginId = "ahsan@school.com", Role = "teacher", CreatedAt = Created,
                    PasswordHash = "$2a$11$PvGvQ3bx/UDjVC9CcTBFF.POtBi5GnNJ0HOyAt4fhTsvU1IDEzEoa" },
                new AppUser { Id = 5, FullName = "Teacher Maryam", LoginId = "maryam@school.com", Role = "teacher", CreatedAt = Created,
                    PasswordHash = "$2a$11$iHSQXgmL3I4mPMVdCiK...me1Q.I8AZCK/4fcH.MwqdJ0hXSqa5CK" },
                new AppUser { Id = 6, FullName = "Teacher Usman", LoginId = "usman@school.com", Role = "teacher", CreatedAt = Created,
                    PasswordHash = "$2a$11$kl2OEPRuYn2EsnpUzv8bbeuzGlNUJyCiLAf6l49ujBC6ygeilXizW" }
            );

            // ---------------- subjects ----------------
            modelBuilder.Entity<Subject>().HasData(
                new Subject { Id = 1, Name = "English", MaxMarks = 100 },
                new Subject { Id = 2, Name = "Mathematics", MaxMarks = 100 },
                new Subject { Id = 3, Name = "Physics", MaxMarks = 60 },
                new Subject { Id = 4, Name = "Chemistry", MaxMarks = 60 },
                new Subject { Id = 5, Name = "Biology", MaxMarks = 60 }
            );

            // ---------------- classes (class teacher in brackets) ----------------
            modelBuilder.Entity<SchoolClass>().HasData(
                new SchoolClass { Id = 1, GradeName = "Class 8", Section = "A", ClassTeacherId = 4 },   // Ahsan
                new SchoolClass { Id = 2, GradeName = "Class 8", Section = "B", ClassTeacherId = 3 },   // Sania
                new SchoolClass { Id = 3, GradeName = "Class 9", Section = "A", ClassTeacherId = 5 },   // Maryam
                new SchoolClass { Id = 4, GradeName = "Class 9", Section = "B", ClassTeacherId = 6 },   // Usman
                new SchoolClass { Id = 5, GradeName = "Class 9", Section = "C", ClassTeacherId = null } // none yet
            );

            // ---------------- students: 5 per class ----------------
            string[][] names =
            {
                new[] { "Ali", "Ayesha", "Hamza", "Hira", "Omar" },          // Class 8 - A
                new[] { "Sarah", "Ahmed", "Zain", "Fatima", "Bilal" },       // Class 8 - B (original)
                new[] { "Saad", "Zara", "Usama", "Mahnoor", "Fahad" },       // Class 9 - A
                new[] { "Danish", "Iqra", "Hassan", "Sana", "Talha" },       // Class 9 - B
                new[] { "Areeba", "Junaid", "Kinza", "Rehan", "Noor" }       // Class 9 - C
            };
            var students = new List<Student>();
            int studentId = 1;
            for (int c = 0; c < names.Length; c++)
            {
                for (int i = 0; i < names[c].Length; i++)
                {
                    students.Add(new Student
                    {
                        Id = studentId++,
                        FullName = names[c][i],
                        RollNo = (i + 1).ToString("00"),   // "01" .. "05"
                        ClassId = c + 1
                    });
                }
            }
            modelBuilder.Entity<Student>().HasData(students);

            // ---------------- teaching assignments: 5 classes x 5 subjects ----------------
            // English = Ahsan(4), Maths = Maryam(5), Physics = Usman(6), Chemistry + Biology = Sania(3)
            int[] teacherOfSubject = { 0, 4, 5, 6, 3, 3 };   // index = subject id
            var assignments = new List<TeachingAssignment>();
            for (int classId = 1; classId <= 5; classId++)
            {
                for (int subjectId = 1; subjectId <= 5; subjectId++)
                {
                    assignments.Add(new TeachingAssignment
                    {
                        Id = (classId - 1) * 5 + subjectId,
                        ClassId = classId,
                        SubjectId = subjectId,
                        TeacherId = teacherOfSubject[subjectId]
                    });
                }
            }

            // ---------------- marks ----------------
            // (class, subject, marks for roll 01..05, submitted?)
            var markSeeds = new List<(int classId, int subjectId, int[] values, bool submitted)>
            {
                (1, 4, new[] { 50, 44, 57, 39, 48 }, true),   // 8-A Chemistry: submitted
                (2, 1, new[] { 85, 78, 66, 91, 72 }, true),   // 8-B English: submitted
                (2, 2, new[] { 92, 81, 59, 88, 70 }, true),   // 8-B Maths: submitted
                (2, 5, new[] { 52, 47, 40, 58, 45 }, true),   // 8-B Biology: submitted
                (2, 3, new[] { 55 }, false),                  // 8-B Physics: in progress (only Sarah)
                (2, 4, new[] { 48 }, false),                  // 8-B Chemistry: in progress (only Sarah)
                (3, 1, new[] { 74, 88, 63, 95, 58 }, true),   // 9-A: everything submitted
                (3, 2, new[] { 67, 90, 72, 84, 49 }, true),
                (3, 3, new[] { 41, 53, 38, 57, 46 }, true),
                (3, 4, new[] { 44, 56, 35, 51, 42 }, true),
                (3, 5, new[] { 49, 58, 43, 54, 37 }, true),
            };
            var marks = new List<Mark>();
            int markId = 1;
            foreach (var seed in markSeeds)
            {
                var assignment = assignments.First(a => a.ClassId == seed.classId && a.SubjectId == seed.subjectId);
                if (seed.submitted)
                {
                    assignment.SubmittedAt = Submitted;
                }
                for (int i = 0; i < seed.values.Length; i++)
                {
                    marks.Add(new Mark
                    {
                        Id = markId++,
                        StudentId = (seed.classId - 1) * 5 + i + 1,   // roll 01 of that class = first student
                        SubjectId = seed.subjectId,
                        Obtained = seed.values[i],
                        EnteredById = assignment.TeacherId,
                        UpdatedAt = Submitted
                    });
                }
            }
            modelBuilder.Entity<TeachingAssignment>().HasData(assignments);
            modelBuilder.Entity<Mark>().HasData(marks);
        }
    }
}
