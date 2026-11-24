@echo off
REM Runs every Postman test against the LIVE API on Azure App Service with Newman
REM and writes an HTML report to postman\reports\azure_test_report.html
REM Before running: the Azure MySQL server must be started (Portal > Start).

set ROOT=%~dp0..
set PATH=%ROOT%\tools\node\node-v26.13.1-win-x64;%PATH%
set BASE=https://school-grading-api-bcgi.azurewebsites.net

REM The Free (F1) plan sleeps when idle: wake it up first (can take 20-30 seconds)
echo Waking up %BASE% ...
curl -s -o nul --max-time 120 %BASE%/swagger/index.html

cd /d "%ROOT%\tools\postman-runner"
call npx newman run "%ROOT%\postman\SchoolGrading.postman_collection.json" ^
  -e "%ROOT%\postman\SchoolGrading_Azure.postman_environment.json" ^
  --timeout-request 60000 ^
  -r cli,htmlextra ^
  --reporter-htmlextra-export "%ROOT%\postman\reports\azure_test_report.html" ^
  --reporter-htmlextra-title "School Grading API - Azure test report" ^
  --reporter-htmlextra-browserTitle "School Grading API tests (Azure)"

echo.
echo Report: %ROOT%\postman\reports\azure_test_report.html
