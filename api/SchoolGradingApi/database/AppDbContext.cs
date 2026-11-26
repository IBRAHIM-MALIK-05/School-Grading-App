using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using SchoolGradingApi.entities;

namespace SchoolGradingApi.database
{
    // The bridge between C# and MySQL.
    // Each DbSet = one table. OnModelCreating = table rules (keys, lengths, relations).
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<AppUser> Users => Set<AppUser>();
        public DbSet<Subject> Subjects => Set<Subject>();
        public DbSet<SchoolClass> Classes => Set<SchoolClass>();
        public DbSet<Student> Students => Set<Student>();
        public DbSet<TeachingAssignment> TeachingAssignments => Set<TeachingAssignment>();
        public DbSet<Mark> Marks => Set<Mark>();
        public DbSet<StudentRemoval> StudentRemovals => Set<StudentRemoval>();
        public DbSet<SchoolSettings> SchoolSettings => Set<SchoolSettings>();
        public DbSet<Notification> Notifications => Set<Notification>();

        // DateOnly (a date without a time, e.g. the Result Date) is saved in a MySQL DATE column.
        // Oracle's MySQL provider reads DATE values back as DateTime, so EF converts them here
        // (DateOnly <-> DateTime at midnight). Used by school_settings and notifications.
        protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
        {
            configurationBuilder.Properties<DateOnly>()
                .HaveConversion<DateOnlyConverter>()
                .HaveColumnType("date");
        }

        private class DateOnlyConverter : ValueConverter<DateOnly, DateTime>
        {
            public DateOnlyConverter()
                : base(d => d.ToDateTime(TimeOnly.MinValue), dt => DateOnly.FromDateTime(dt))
            {
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // ---------------- users ----------------
            modelBuilder.Entity<AppUser>().ToTable("users");

            modelBuilder.Entity<AppUser>()
                .Property(e => e.FullName)
                .HasMaxLength(100)
                .IsRequired();

            modelBuilder.Entity<AppUser>()
                .Property(e => e.LoginId)
                .HasMaxLength(100)
                .IsRequired();

            modelBuilder.Entity<AppUser>()
                .HasIndex(e => e.LoginId)
                .IsUnique();                      // no two users with the same Login ID

            modelBuilder.Entity<AppUser>()
                .Property(e => e.ContactEmail)
                .HasMaxLength(150);

            modelBuilder.Entity<AppUser>()
                .Property(e => e.PasswordHash)
                .HasMaxLength(100)
                .IsRequired();

            modelBuilder.Entity<AppUser>()
                .Property(e => e.Role)
                .HasMaxLength(20)
                .IsRequired();

            // Soft delete: EF adds "WHERE isDeleted = 0" to EVERY query on users by itself,
            // so a deleted user disappears from lists, pickers and login without extra code.
            // Only GetDeleted / RestoreById / HardDeleteById use .IgnoreQueryFilters() to see them.
            modelBuilder.Entity<AppUser>()
                .HasQueryFilter(e => !e.isDeleted);

            // ---------------- subjects ----------------
            modelBuilder.Entity<Subject>().ToTable("subjects");

            modelBuilder.Entity<Subject>()
                .Property(e => e.Name)
                .HasMaxLength(50)
                .IsRequired();

            modelBuilder.Entity<Subject>()
                .HasIndex(e => e.Name)
                .IsUnique();

            // ---------------- classes ----------------
            modelBuilder.Entity<SchoolClass>().ToTable("classes");

            modelBuilder.Entity<SchoolClass>()
                .Property(e => e.GradeName)
                .HasMaxLength(20)
                .IsRequired();

            modelBuilder.Entity<SchoolClass>()
                .Property(e => e.Section)
                .HasMaxLength(5)
                .IsRequired();

            modelBuilder.Entity<SchoolClass>()
                .HasIndex(e => new { e.GradeName, e.Section })
                .IsUnique();                      // only one "Class 8 - B"

            // Soft delete: deleted classes are left out of every query automatically
            // (and so are their students / subjects when loaded through the class).
            modelBuilder.Entity<SchoolClass>()
                .HasQueryFilter(e => !e.isDeleted);

            // classes.ClassTeacherId -> users.Id  (a teacher leads at most 1 class)
            modelBuilder.Entity<SchoolClass>()
                .HasOne(e => e.ClassTeacher)
                .WithMany()
                .HasForeignKey(e => e.ClassTeacherId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<SchoolClass>()
                .HasIndex(e => e.ClassTeacherId)
                .IsUnique();

            // ---------------- students ----------------
            modelBuilder.Entity<Student>().ToTable("students");

            modelBuilder.Entity<Student>()
                .Property(e => e.FullName)
                .HasMaxLength(100)
                .IsRequired();

            modelBuilder.Entity<Student>()
                .Property(e => e.RollNo)
                .HasMaxLength(10)
                .IsRequired();

            // students.ClassId -> classes.Id
            modelBuilder.Entity<Student>()
                .HasOne(e => e.SchoolClass)
                .WithMany(c => c.Students)
                .HasForeignKey(e => e.ClassId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Student>()
                .HasIndex(e => new { e.ClassId, e.RollNo })
                .IsUnique();                      // roll numbers unique inside a class

            // ---------------- teaching_assignments ----------------
            modelBuilder.Entity<TeachingAssignment>().ToTable("teaching_assignments");

            modelBuilder.Entity<TeachingAssignment>()
                .HasOne(e => e.SchoolClass)
                .WithMany(c => c.Assignments)
                .HasForeignKey(e => e.ClassId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<TeachingAssignment>()
                .HasOne(e => e.Subject)
                .WithMany()
                .HasForeignKey(e => e.SubjectId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<TeachingAssignment>()
                .HasOne(e => e.Teacher)
                .WithMany()
                .HasForeignKey(e => e.TeacherId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<TeachingAssignment>()
                .HasIndex(e => new { e.ClassId, e.SubjectId })
                .IsUnique();                      // one teacher per subject per class

            // ---------------- marks ----------------
            modelBuilder.Entity<Mark>().ToTable("marks");

            // marks.StudentId -> students.Id  (delete student = delete their marks)
            modelBuilder.Entity<Mark>()
                .HasOne(e => e.Student)
                .WithMany(s => s.Marks)
                .HasForeignKey(e => e.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Mark>()
                .HasOne(e => e.Subject)
                .WithMany()
                .HasForeignKey(e => e.SubjectId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Mark>()
                .HasOne(e => e.EnteredBy)
                .WithMany()
                .HasForeignKey(e => e.EnteredById)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Mark>()
                .HasIndex(e => new { e.StudentId, e.SubjectId })
                .IsUnique();                      // one mark per student per subject

            // ---------------- student_removals (notices for subject teachers) ----------------
            modelBuilder.Entity<StudentRemoval>().ToTable("student_removals");

            modelBuilder.Entity<StudentRemoval>()
                .Property(e => e.StudentName)
                .HasMaxLength(100)
                .IsRequired();

            modelBuilder.Entity<StudentRemoval>()
                .Property(e => e.RollNo)
                .HasMaxLength(10)
                .IsRequired();

            modelBuilder.Entity<StudentRemoval>()
                .Property(e => e.RemovedByRole)
                .HasMaxLength(20)
                .IsRequired();

            modelBuilder.Entity<StudentRemoval>()
                .HasOne(e => e.SchoolClass)
                .WithMany()
                .HasForeignKey(e => e.ClassId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<StudentRemoval>()
                .HasOne(e => e.RemovedBy)
                .WithMany()
                .HasForeignKey(e => e.RemovedById)
                .OnDelete(DeleteBehavior.Restrict);

            // ---------------- school_settings (one row: the Result Date) ----------------
            modelBuilder.Entity<SchoolSettings>().ToTable("school_settings");

            modelBuilder.Entity<SchoolSettings>()
                .Property(e => e.Id)
                .ValueGeneratedNever();           // always Id = 1, never AUTO_INCREMENT

            // school_settings.UpdatedByUserId -> users.Id (deleting that user keeps the date)
            modelBuilder.Entity<SchoolSettings>()
                .HasOne(e => e.UpdatedByUser)
                .WithMany()
                .HasForeignKey(e => e.UpdatedByUserId)
                .OnDelete(DeleteBehavior.SetNull);

            // ---------------- notifications (the Notification Bell) ----------------
            modelBuilder.Entity<Notification>().ToTable("notifications");

            modelBuilder.Entity<Notification>()
                .Property(e => e.Type)
                .HasMaxLength(40)
                .IsRequired();

            modelBuilder.Entity<Notification>()
                .Property(e => e.Title)
                .HasMaxLength(150)
                .IsRequired();

            modelBuilder.Entity<Notification>()
                .Property(e => e.Message)
                .HasMaxLength(1000)
                .IsRequired();

            modelBuilder.Entity<Notification>()
                .Property(e => e.IsRead)
                .HasDefaultValue(false);

            // notifications.RecipientUserId -> users.Id (a user removed for ever loses their inbox)
            modelBuilder.Entity<Notification>()
                .HasOne(e => e.RecipientUser)
                .WithMany()
                .HasForeignKey(e => e.RecipientUserId)
                .OnDelete(DeleteBehavior.Cascade);

            // notifications.SenderUserId -> users.Id (null = automatic system reminder)
            modelBuilder.Entity<Notification>()
                .HasOne(e => e.SenderUser)
                .WithMany()
                .HasForeignKey(e => e.SenderUserId)
                .OnDelete(DeleteBehavior.SetNull);

            // notifications.AssignmentId -> teaching_assignments.Id (which subject + class)
            modelBuilder.Entity<Notification>()
                .HasOne(e => e.Assignment)
                .WithMany()
                .HasForeignKey(e => e.AssignmentId)
                .OnDelete(DeleteBehavior.SetNull);

            // Fast "do I already have today's reminder of this type?" check (deduplication)
            modelBuilder.Entity<Notification>()
                .HasIndex(e => new { e.RecipientUserId, e.NotificationDate, e.Type });

            // ---------------- demo data ----------------
            SeedData.Add(modelBuilder);
        }
    }
}
