"""Builds the Postman collection + environments in /postman (Postman v2.1 format).

    tools\\.venv\\Scripts\\python -I tools\\postman\\build_collection.py

Every request has test scripts (pm.test) that check the status code and the JSON.
Login requests save their JWT into collection variables, so later requests can
send "Authorization: Bearer {{adminToken}}" etc.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "postman"


# ------------------------------------------------------------------ helpers
def status(code, text=None):
    names = {200: "OK", 201: "Created", 400: "Bad Request", 401: "Unauthorized",
             403: "Forbidden", 404: "Not Found", 409: "Conflict"}
    return [f'pm.test("Status is {code} {text or names.get(code, "")}", () => pm.response.to.have.status({code}));']


def message(part):
    return [f'pm.test("Error message mentions \\"{part}\\"", () => pm.expect(pm.response.json().message).to.include("{part}"));']


def fast():
    return ['pm.test("Response time under 3 seconds", () => pm.expect(pm.response.responseTime).to.be.below(3000));']


def request(name, method, path, token=None, body=None, tests=(), pre=(), description=""):
    item = {
        "name": name,
        "event": [{"listen": "test", "script": {"type": "text/javascript", "exec": list(tests)}}],
        "request": {
            "method": method,
            "header": [],
            "auth": ({"type": "bearer", "bearer": [{"key": "token", "value": "{{" + token + "}}", "type": "string"}]}
                     if token else {"type": "noauth"}),
            "url": {
                "raw": "{{baseUrl}}" + path,
                "host": ["{{baseUrl}}"],
                "path": [p for p in path.split("/") if p],
            },
            "description": description,
        },
    }
    if pre:
        item["event"].insert(0, {"listen": "prerequest", "script": {"type": "text/javascript", "exec": list(pre)}})
    if body is not None:
        item["request"]["header"].append({"key": "Content-Type", "value": "application/json"})
        raw = body if isinstance(body, str) else json.dumps(body, indent=2)
        item["request"]["body"] = {"mode": "raw", "raw": raw, "options": {"raw": {"language": "json"}}}
    return item


def folder(name, description, items):
    return {"name": name, "description": description, "item": items}


def login(name, login_id, password, save_as, extra=()):
    return request(
        name, "POST", "/auth/login", body={"loginId": login_id, "password": password},
        tests=status(200) + fast() + [
            "const json = pm.response.json();",
            'pm.test("Response has a JWT token", () => pm.expect(json.token).to.be.a("string").and.not.empty);',
            'pm.test("Password hash is never returned", () => pm.expect(json.user).to.not.have.property("passwordHash"));',
            f'pm.collectionVariables.set("{save_as}", json.token);',
        ] + list(extra),
        description=f"Logs in as {login_id} and saves the JWT into the collection variable **{save_as}**.",
    )


# ------------------------------------------------------------------ 1. login
f1 = folder("1. Auth - Login", "Log in as each role and keep their JWT tokens for the next requests.", [
    login("Login - Admin", "admin@school.com", "123", "adminToken",
          ['pm.test("Role is admin", () => pm.expect(json.user.role).to.eql("admin"));']),
    login("Login - Principal / VP", "vp@school.com", "123", "vpToken",
          ['pm.test("Role is vp", () => pm.expect(json.user.role).to.eql("vp"));']),
    login("Login - Teacher Sania (Class Teacher of 8-B)", "sania@school.com", "123", "saniaToken",
          ['pm.test("Sania is Class Teacher of Class 8 - B", () => pm.expect(json.user.classTeacherOfClassName).to.eql("Class 8 - B"));']),
    login("Login - Teacher Maryam (Class Teacher of 9-A)", "maryam@school.com", "123", "maryamToken"),
    request("Login - wrong password", "POST", "/auth/login",
            body={"loginId": "sania@school.com", "password": "wrong"},
            tests=status(401) + message("Invalid Login ID or password"),
            description="Error case: wrong password returns 401 with a JSON message (same message for an unknown Login ID)."),
])

# ------------------------------------------------------------------ 2. accounts
f2 = folder("2. Auth - Create account & first login",
            "Admin creates an account (registration). The new user must change the temporary password before using the app.", [
    request("Register - new Teacher (Admin)", "POST", "/auth/register", token="adminToken",
            body={"fullName": "Teacher Ali Raza", "role": "teacher", "contactEmail": "ali.raza@gmail.com",
                  "classTeacherOfClassId": None, "assignmentIds": []},
            tests=status(201) + [
                "const json = pm.response.json();",
                'pm.test("Login ID is generated (…@school.com)", () => pm.expect(json.loginId).to.match(/^ali\\d*@school\\.com$/));',
                'pm.test("Temporary password has 10 characters", () => pm.expect(json.temporaryPassword).to.have.lengthOf(10));',
                'pm.collectionVariables.set("newLoginId", json.loginId);',
                'pm.collectionVariables.set("newTempPassword", json.temporaryPassword);',
            ],
            description="Admin creates a Teacher. The server generates the Login ID and a temporary password (shown once)."),
    request("Register - class already has a Class Teacher", "POST", "/auth/register", token="adminToken",
            body={"fullName": "Teacher Test", "role": "teacher", "contactEmail": "test@gmail.com",
                  "classTeacherOfClassId": 2, "assignmentIds": []},
            tests=status(409) + message("already has a Class Teacher")),
    request("Register - invalid email", "POST", "/auth/register", token="adminToken",
            body={"fullName": "Teacher Test", "role": "teacher", "contactEmail": "not-an-email", "assignmentIds": []},
            tests=status(400) + message("valid email")),
    request("Register - by a Teacher (not allowed)", "POST", "/auth/register", token="saniaToken",
            body={"fullName": "Teacher Test", "role": "teacher", "contactEmail": "test@gmail.com", "assignmentIds": []},
            tests=status(403) + message("Only the Admin")),
    request("Register - without a token", "POST", "/auth/register",
            body={"fullName": "Teacher Test", "role": "teacher", "contactEmail": "test@gmail.com", "assignmentIds": []},
            tests=status(401), description="No Authorization header -> 401 from the JWT middleware."),
    request("Login - new Teacher with temporary password", "POST", "/auth/login",
            body='{\n  "loginId": "{{newLoginId}}",\n  "password": "{{newTempPassword}}"\n}',
            tests=status(200) + [
                "const json = pm.response.json();",
                'pm.test("Must change password is true", () => pm.expect(json.user.mustChangePassword).to.be.true);',
                'pm.collectionVariables.set("newToken", json.token);',
            ]),
    request("New Teacher - blocked until password is changed", "GET", "/assignments/mine", token="newToken",
            tests=status(403) + message("change your temporary password")),
    request("Change password - too weak", "POST", "/auth/change-password", token="newToken",
            body='{\n  "currentPassword": "{{newTempPassword}}",\n  "newPassword": "abcdefgh"\n}',
            tests=status(400) + message("one letter and one number")),
    request("Change password - wrong current password", "POST", "/auth/change-password", token="newToken",
            body={"currentPassword": "wrong-password", "newPassword": "NewPass123"},
            tests=status(400) + message("Current password is incorrect")),
    request("Change password - success", "POST", "/auth/change-password", token="newToken",
            body='{\n  "currentPassword": "{{newTempPassword}}",\n  "newPassword": "NewPass123"\n}',
            tests=status(200) + [
                'pm.test("Must change password is now false", () => pm.expect(pm.response.json().mustChangePassword).to.be.false);']),
    request("New Teacher - now allowed in", "GET", "/assignments/mine", token="newToken",
            tests=status(200) + ['pm.test("Returns a list", () => pm.expect(pm.response.json()).to.be.an("array"));']),
])

# ------------------------------------------------------------------ 3. users + reset
f3 = folder("3. Users & password reset (Admin)", "Only the Admin can list users and reset forgotten passwords.", [
    request("Users - list (Admin)", "GET", "/users", token="adminToken",
            tests=status(200) + fast() + [
                "const users = pm.response.json();",
                'pm.test("At least the 6 demo users", () => pm.expect(users.length).to.be.at.least(6));',
                'pm.test("No password hashes in the response", () => users.forEach(u => pm.expect(u).to.not.have.property("passwordHash")));',
                'const me = users.find(u => u.loginId === pm.collectionVariables.get("newLoginId"));',
                'pm.test("New Teacher is in the list", () => pm.expect(me).to.not.be.undefined);',
                'pm.collectionVariables.set("newUserId", me.id);',
            ]),
    request("Users - list as Principal/VP (not allowed)", "GET", "/users", token="vpToken", tests=status(403)),
    request("Users - list without a token", "GET", "/users", tests=status(401)),
    request("Reset password - Admin resets the new Teacher", "POST", "/auth/reset-password/{{newUserId}}", token="adminToken",
            tests=status(200) + [
                'pm.test("A new temporary password is returned", () => pm.expect(pm.response.json().temporaryPassword).to.have.lengthOf(10));']),
    request("Login - old password stops working after reset", "POST", "/auth/login",
            body='{\n  "loginId": "{{newLoginId}}",\n  "password": "NewPass123"\n}',
            tests=status(401)),
    request("Reset password - own account (not allowed)", "POST", "/auth/reset-password/1", token="adminToken",
            tests=status(400) + message("Change Password")),
    request("Reset password - user not found", "POST", "/auth/reset-password/99999", token="adminToken",
            tests=status(404)),
])

# ------------------------------------------------------------------ 4. classes
f4 = folder("4. Classes, tracker & students", "School overview, the Class Teacher's live tracker, and student management.", [
    request("Overview - Admin", "GET", "/classes", token="adminToken",
            tests=status(200) + fast() + [
                "const o = pm.response.json();",
                'pm.test("5 sections", () => pm.expect(o.sections).to.eql(5));',
                'pm.test("Each class has 5 subjects", () => o.classes.forEach(c => pm.expect(c.subjects).to.have.lengthOf(5)));',
            ]),
    request("Overview - Teacher (not allowed)", "GET", "/classes", token="saniaToken", tests=status(403)),
    request("Tracker 8-B - Class Teacher Sania", "GET", "/classes/2/tracker", token="saniaToken",
            tests=status(200) + [
                "const t = pm.response.json();",
                'pm.test("Tracker lists the 5 subjects", () => pm.expect(t.subjects).to.have.lengthOf(5));',
                'pm.test("Each subject shows its teacher and progress", () => t.subjects.forEach(s => { pm.expect(s.teacherName).to.be.a("string"); pm.expect(s.enteredCount).to.be.at.most(s.studentCount); }));',
            ]),
    request("Tracker 9-A - not her class", "GET", "/classes/3/tracker", token="saniaToken",
            tests=status(403) + message("Only the Class Teacher")),
    request("Tracker - class not found", "GET", "/classes/999/tracker", token="vpToken", tests=status(404)),
    request("Publish 8-B - subjects still pending", "PUT", "/classes/2/publish", token="saniaToken",
            body={"publish": True}, tests=status(409) + message("Still waiting for")),
    request("Students of 8-B", "GET", "/classes/2/students", token="saniaToken",
            tests=status(200) + ['pm.test("At least 5 students", () => pm.expect(pm.response.json().students.length).to.be.at.least(5));']),
    request("Add student to 8-B", "POST", "/classes/2/students", token="saniaToken",
            body={"fullName": "Hamza Ali", "rollNo": "6"},
            tests=status(201) + [
                "const s = pm.response.json();",
                'pm.test("Roll number is padded to 06", () => pm.expect(s.rollNo).to.eql("06"));',
                'pm.collectionVariables.set("newStudentId", s.id);',
            ]),
    request("Add student - duplicate roll number", "POST", "/classes/2/students", token="saniaToken",
            body={"fullName": "Someone Else", "rollNo": "06"}, tests=status(409) + message("already exists")),
    request("Add student - empty name", "POST", "/classes/2/students", token="saniaToken",
            body={"fullName": "", "rollNo": "07"}, tests=status(400) + message("required")),
    request("Tracker 8-B - submissions cleared after adding a student", "GET", "/classes/2/tracker", token="saniaToken",
            tests=status(200) + [
                'pm.test("No subject is \\"submitted\\" any more", () => pm.response.json().subjects.forEach(s => pm.expect(s.submittedAt).to.be.null));']),
])

# ------------------------------------------------------------------ 5. marks
marks_body_pre = [
    "// Builds the request body from the students saved by 'Marks of 8-B Chemistry'",
    'const rows = JSON.parse(pm.collectionVariables.get("chem8bRows"));',
]
f5 = folder("5. Marks upload & update", "Subject teachers upload marks (draft or submit). Rules: 0..max, all students before submit.", [
    request("My subjects - Teacher Sania", "GET", "/assignments/mine", token="saniaToken",
            tests=status(200) + [
                "const list = pm.response.json();",
                'pm.test("Sania teaches 10 class-subjects", () => pm.expect(list).to.have.lengthOf(10));',
                'const chem = list.find(a => a.subjectName === "Chemistry" && a.className === "Class 8 - B");',
                'pm.collectionVariables.set("chem8bId", chem.id);',
            ]),
    request("My subjects - Admin (not a teacher)", "GET", "/assignments/mine", token="adminToken",
            tests=status(403) + message("Only teachers")),
    request("Marks of 8-B Chemistry", "GET", "/assignments/{{chem8bId}}/marks", token="saniaToken",
            tests=status(200) + [
                "const marksData = pm.response.json();  // (\"data\" is a reserved name in Postman)",
                'pm.test("Max marks is 60", () => pm.expect(marksData.assignment.maxMarks).to.eql(60));',
                'pm.collectionVariables.set("chem8bRows", JSON.stringify(marksData.rows));',
            ]),
    request("Save marks - above the maximum (61/60)", "PUT", "/assignments/{{chem8bId}}/marks", token="saniaToken",
            pre=marks_body_pre + [
                'pm.collectionVariables.set("marksBody", JSON.stringify({ marks: [{ studentId: rows[0].studentId, obtained: 61 }], submit: false }, null, 2));'],
            body="{{marksBody}}", tests=status(400) + message("between 0 and 60")),
    request("Submit marks - one student still empty", "PUT", "/assignments/{{chem8bId}}/marks", token="saniaToken",
            pre=marks_body_pre + [
                "const marks = rows.map((r, i) => ({ studentId: r.studentId, obtained: i === rows.length - 1 ? null : 40 }));",
                'pm.collectionVariables.set("marksBody", JSON.stringify({ marks: marks, submit: true }, null, 2));'],
            body="{{marksBody}}", tests=status(400) + message("cannot submit")),
    request("Submit marks - every student (success)", "PUT", "/assignments/{{chem8bId}}/marks", token="saniaToken",
            pre=marks_body_pre + [
                "const marks = rows.map(r => ({ studentId: r.studentId, obtained: 40 }));",
                'pm.collectionVariables.set("marksBody", JSON.stringify({ marks: marks, submit: true }, null, 2));'],
            body="{{marksBody}}", tests=status(200) + [
                'pm.test("Says submitted", () => pm.expect(pm.response.json().message).to.eql("Marks submitted."));']),
    request("Marks of another teacher's subject", "GET", "/assignments/1/marks", token="saniaToken",
            tests=status(403) + message("not assigned to you")),
])

# ------------------------------------------------------------------ 6. students
f6 = folder("6. Result cards & delete student", "Report cards (Class Teacher, VP, Admin) and deleting a student.", [
    request("Result card - Sarah (complete)", "GET", "/students/6/report-card", token="saniaToken",
            tests=status(200) + [
                "const card = pm.response.json();",
                'pm.test("Complete card has a percentage and a grade", () => { pm.expect(card.isComplete).to.be.true; pm.expect(card.grade).to.be.a("string"); });',
                'pm.test("Total is out of 380", () => pm.expect(card.totalMax).to.eql(380));',
            ]),
    request("Result card - Ahmed (Physics still pending)", "GET", "/students/7/report-card", token="vpToken",
            tests=status(200) + [
                "const card = pm.response.json();",
                'pm.test("Incomplete card has no grade yet", () => { pm.expect(card.isComplete).to.be.false; pm.expect(card.grade).to.be.null; });',
            ]),
    request("Result card - teacher of another class (not allowed)", "GET", "/students/6/report-card", token="maryamToken",
            tests=status(403)),
    request("Delete student - the one added earlier", "DELETE", "/students/{{newStudentId}}", token="saniaToken",
            tests=status(200) + message("deleted")),
    request("Delete student - not found", "DELETE", "/students/99999", token="saniaToken", tests=status(404)),
])

# ------------------------------------------------------------------ 7. publish
f7 = folder("7. Publish & lock results", "The Class Teacher publishes results: marks and students of that class are locked.", [
    request("Publish 9-A - Class Teacher Maryam", "PUT", "/classes/3/publish", token="maryamToken",
            body={"publish": True}, tests=status(200) + message("published")),
    request("Overview - Cards Ready now counts 9-A", "GET", "/classes", token="vpToken",
            tests=status(200) + [
                'pm.test("Cards Ready is at least 5", () => pm.expect(pm.response.json().cardsReady).to.be.at.least(5));']),
    request("Add student to locked 9-A", "POST", "/classes/3/students", token="maryamToken",
            body={"fullName": "Late Student", "rollNo": "09"}, tests=status(409) + message("published")),
    request("Save marks in locked 9-A", "PUT", "/assignments/12/marks", token="maryamToken",
            body={"marks": [], "submit": False}, tests=status(409) + message("locked")),
    request("Publish 9-A - not the Class Teacher", "PUT", "/classes/3/publish", token="saniaToken",
            body={"publish": False}, tests=status(403)),
    request("Unpublish 9-A - Maryam (unlock again)", "PUT", "/classes/3/publish", token="maryamToken",
            body={"publish": False}, tests=status(200) + message("unpublished")),
])

# ------------------------------------------------------------------ files
collection = {
    "info": {
        "name": "School Grading API",
        "description": (
            "Tests for the School Grading ASP.NET Core Web API.\n\n"
            "1. Select an environment (**School Grading - Local** or **- Azure**).\n"
            "2. Run the whole collection (Run collection) - the folders are in order.\n"
            "Login requests save JWT tokens into collection variables automatically.\n"
            "The collection puts the data back the way it was (deletes the student it adds, unpublishes 9-A)."
        ),
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    },
    "item": [f1, f2, f3, f4, f5, f6, f7],
    "variable": [{"key": k, "value": ""} for k in [
        "adminToken", "vpToken", "saniaToken", "maryamToken", "newToken", "newLoginId", "newTempPassword",
        "newUserId", "newStudentId", "chem8bId", "chem8bRows", "marksBody"]],
}


def environment(name, base_url):
    return {
        "name": name,
        "values": [{"key": "baseUrl", "value": base_url, "type": "default", "enabled": True}],
        "_postman_variable_scope": "environment",
    }


OUT.mkdir(exist_ok=True)
(OUT / "SchoolGrading.postman_collection.json").write_text(json.dumps(collection, indent=2), encoding="utf-8")
(OUT / "SchoolGrading_Local.postman_environment.json").write_text(
    json.dumps(environment("School Grading - Local", "http://localhost:5080/api"), indent=2), encoding="utf-8")
count = sum(len(f["item"]) for f in collection["item"])
tests = sum(sum(1 for line in r["event"][-1]["script"]["exec"] if line.startswith("pm.test"))
            for f in collection["item"] for r in f["item"])
print(f"collection: {len(collection['item'])} folders, {count} requests, {tests} tests")
