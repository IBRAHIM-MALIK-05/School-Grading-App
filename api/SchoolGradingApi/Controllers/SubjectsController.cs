using Microsoft.AspNetCore.Mvc;
using SchoolGradingApi.database;
using SchoolGradingApi.Dtos;
using SchoolGradingApi.entities;

namespace SchoolGradingApi.Controllers
{
    // Admin > Subjects: list, add, rename / change max marks, delete (only if unused)
    [Route("api/subjects")]
    public class SubjectsController : AppControllerBase
    {
        public SubjectsController(AppDbContext db) : base(db)
        {
        }

        // 18) GET /api/subjects  -> every subject + in how many classes it is taught
        [HttpGet]
        public IActionResult GetAll()
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can manage classes and subjects.");

            var subjects = _db.Subjects
                .OrderBy(s => s.Name)
                .Select(s => new SubjectDto
                {
                    Id = s.Id,
                    Name = s.Name,
                    MaxMarks = s.MaxMarks,
                    ClassCount = _db.TeachingAssignments.Count(a => a.SubjectId == s.Id)
                })
                .ToList();
            return Ok(subjects);
        }

        // 20) POST /api/subjects  -> Admin adds a subject (e.g. "Computer Science", out of 100)
        [HttpPost]
        public IActionResult Create(SaveSubjectDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can add subjects.");

            var name = (dto.Name ?? "").Trim();
            var problem = CheckSubject(name, dto.MaxMarks, null);
            if (problem != null) return problem;

            var subject = new Subject { Name = name, MaxMarks = dto.MaxMarks };
            _db.Subjects.Add(subject);
            _db.SaveChanges();
            return StatusCode(201, ToDto(subject));
        }

        // 21) PUT /api/subjects/{id}  -> Admin renames a subject or changes its maximum marks
        [HttpPut("{id}")]
        public IActionResult Edit(int id, SaveSubjectDto dto)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can edit subjects.");

            var subject = _db.Subjects.FirstOrDefault(s => s.Id == id);
            if (subject == null) return Error(404, "Subject not found.");

            var name = (dto.Name ?? "").Trim();
            var problem = CheckSubject(name, dto.MaxMarks, id);
            if (problem != null) return problem;

            // Lowering the maximum below a mark that was already given would make that mark invalid
            var highest = _db.Marks.Where(m => m.SubjectId == id).Select(m => (int?)m.Obtained).Max();
            if (highest != null && dto.MaxMarks < highest)
                return Error(409, "A student already has " + highest + " marks in " + subject.Name +
                                  ", so the maximum cannot be lower than " + highest + ".");

            subject.Name = name;
            subject.MaxMarks = dto.MaxMarks;
            _db.SaveChanges();
            return Ok(ToDto(subject));
        }

        // 22) DELETE /api/subjects/{id}  -> only a subject that is not taught in any class and has no marks
        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var me = GetCurrentUser();
            if (me == null) return NotLoggedIn();
            if (me.MustChangePassword) return MustChangePasswordFirst();
            if (me.Role != "admin") return Error(403, "Only the Admin can delete subjects.");

            var subject = _db.Subjects.FirstOrDefault(s => s.Id == id);
            if (subject == null) return Error(404, "Subject not found.");

            int classCount = _db.TeachingAssignments.Count(a => a.SubjectId == id);
            if (classCount > 0)
                return Error(409, subject.Name + " is taught in " + classCount + " class(es). " +
                                  "Remove it from those classes first.");
            if (_db.Marks.Any(m => m.SubjectId == id))
                return Error(409, subject.Name + " already has marks, so it cannot be deleted.");

            _db.Subjects.Remove(subject);
            _db.SaveChanges();
            return Ok(new { message = subject.Name + " was deleted." });
        }

        // ----- helpers -----

        // Name required, not too long, unique (ignoring upper/lower case); max marks 1..1000
        private IActionResult? CheckSubject(string name, int maxMarks, int? thisId)
        {
            if (name == "") return Error(400, "Subject name is required.");
            if (name.Length > SaveSubjectDto.MaxNameLength)
                return Error(400, "Subject name can be at most " + SaveSubjectDto.MaxNameLength + " characters.");
            if (maxMarks < 1 || maxMarks > SaveSubjectDto.HighestMaxMarks)
                return Error(400, "Maximum marks must be between 1 and " + SaveSubjectDto.HighestMaxMarks + ".");

            var lower = name.ToLower();
            var duplicate = _db.Subjects.FirstOrDefault(s => s.Name.ToLower() == lower && s.Id != thisId);
            if (duplicate != null) return Error(409, "A subject called " + duplicate.Name + " already exists.");
            return null;
        }

        private SubjectDto ToDto(Subject s)
        {
            return new SubjectDto
            {
                Id = s.Id,
                Name = s.Name,
                MaxMarks = s.MaxMarks,
                ClassCount = _db.TeachingAssignments.Count(a => a.SubjectId == s.Id)
            };
        }
    }
}
