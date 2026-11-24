// lib/services/api_config.dart
// WHERE the .NET API lives. Change this ONE line to point the app somewhere else:
//   Cloud (Azure App Service)        : 'https://school-grading-api-bcgi.azurewebsites.net/api'  (current)
//   Chrome / Windows on this laptop  : 'http://localhost:5080/api'
//   Android emulator + local API     : 'http://10.0.2.2:5080/api'   (10.0.2.2 = the laptop)

const String apiBaseUrl = 'https://school-grading-api-bcgi.azurewebsites.net/api';

// How long we wait for the server before showing an error.
// The free Azure plan (F1) "sleeps" when idle, so the first request can take ~20-30 s.
const Duration apiTimeout = Duration(seconds: 45);
