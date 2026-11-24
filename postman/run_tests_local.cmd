@echo off
REM Runs every Postman test against the LOCAL API with Newman (Postman's command-line runner)
REM and writes an HTML report to postman\reports\local_test_report.html
REM Before running: XAMPP MySQL on, and the API running (Visual Studio > Run, http profile).

set ROOT=%~dp0..
set PATH=%ROOT%\tools\node\node-v26.13.1-win-x64;%PATH%

cd /d "%ROOT%\tools\postman-runner"
call npx newman run "%ROOT%\postman\SchoolGrading.postman_collection.json" ^
  -e "%ROOT%\postman\SchoolGrading_Local.postman_environment.json" ^
  -r cli,htmlextra ^
  --reporter-htmlextra-omitHeaders Authorization ^
  --reporter-htmlextra-export "%ROOT%\postman\reports\local_test_report.html" ^
  --reporter-htmlextra-title "School Grading API - Local test report" ^
  --reporter-htmlextra-browserTitle "School Grading API tests"

set RESULT=%ERRORLEVEL%

REM Remove every JWT (login token) from the HTML report - it is committed to a public repo
node "%ROOT%\postman\redact_tokens.js" "%ROOT%\postman\reports\local_test_report.html"

echo.
echo Report: %ROOT%\postman\reports\local_test_report.html
exit /b %RESULT%
