// lib/services/current_service.dart
// THE ONE LINE that decides where the app's data comes from.
//   Milestone 1 -> MockDataService()  (fake data in memory, now deleted)
//   Milestone 7 -> ApiDataService()   (real ASP.NET Core API + MySQL)

import 'api_data_service.dart';
import 'data_service.dart';

final DataService dataService = ApiDataService();
