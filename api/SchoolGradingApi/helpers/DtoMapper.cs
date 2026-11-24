using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;

namespace SchoolGradingApi.helpers
{
    // Converts database rows (entities) into DTOs (what we send as JSON).
    // Used by more than one controller, so it lives here instead of being copied.
    public static class DtoMapper
    {
        public static string ClassName(SchoolClass c)
        {
            return c.GradeName + " - " + c.Section;   // "Class 8 - B"
        }

        public static UserDto ToUserDto(AppUser user, SchoolClass? classTeacherOf)
        {
            return new UserDto
            {
                Id = user.Id,
                FullName = user.FullName,
                LoginId = user.LoginId,
                Role = user.Role,
                ContactEmail = user.ContactEmail,
                MustChangePassword = user.MustChangePassword,
                ClassTeacherOfClassId = classTeacherOf?.Id,
                ClassTeacherOfClassName = classTeacherOf == null ? null : ClassName(classTeacherOf)
            };
        }

        public static StudentDto ToStudentDto(Student s)
        {
            return new StudentDto { Id = s.Id, FullName = s.FullName, RollNo = s.RollNo, ClassId = s.ClassId };
        }

        // Needs: ClassTeacher, Students, Assignments (+ Subject, Teacher) loaded with .Include()
        public static SchoolClassDto ToSchoolClassDto(SchoolClass c)
        {
            return new SchoolClassDto
            {
                Id = c.Id,
                GradeName = c.GradeName,
                Section = c.Section,
                ClassTeacherId = c.ClassTeacherId,
                ClassTeacherName = c.ClassTeacher?.FullName,
                StudentCount = c.Students.Count,
                IsPublished = c.ResultsPublishedAt != null,
                Subjects = c.Assignments
                    .OrderBy(a => a.SubjectId)
                    .Select(a => new ClassSubjectDto
                    {
                        AssignmentId = a.Id,
                        SubjectId = a.SubjectId,
                        SubjectName = a.Subject!.Name,
                        MaxMarks = a.Subject.MaxMarks,
                        TeacherId = a.TeacherId,
                        TeacherName = a.Teacher?.FullName,
                        IsSubmitted = a.SubmittedAt != null
                    })
                    .ToList()
            };
        }
    }
}
