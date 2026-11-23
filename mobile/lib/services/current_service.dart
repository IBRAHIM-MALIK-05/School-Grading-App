// lib/services/current_service.dart
// THE ONE LINE that decides where the app's data comes from.
//   Milestone 1 -> MockDataService()  (fake data in memory)
//   Milestone 7 -> ApiDataService()   (real ASP.NET Core API + MySQL)

import 'data_service.dart';
import 'mock_data_service.dart';

final DataService dataService = MockDataService();
