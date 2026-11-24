// lib/services/api_config.dart
// WHERE the .NET API lives. Change this ONE line to point the app somewhere else:
//   Chrome / Windows on this laptop : 'http://localhost:5080/api'   (default)
//   Android emulator                : 'http://10.0.2.2:5080/api'    (10.0.2.2 = the laptop)
//   Cloud (Azure, Milestone 6)      : 'https://<app-name>.azurewebsites.net/api'

const String apiBaseUrl = 'http://localhost:5080/api';

// How long we wait for the server before showing an error
const Duration apiTimeout = Duration(seconds: 20);
