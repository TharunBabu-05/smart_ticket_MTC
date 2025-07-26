// Simple test file to verify compilation
import 'package:flutter/material.dart';
import 'lib/services/enhanced_auth_service.dart';
import 'lib/services/theme_service.dart';
import 'lib/services/offline_storage_service.dart';
import 'lib/services/performance_service.dart';

void main() {
  print('All services imported successfully!');
  print('Enhanced Auth Service: ${EnhancedAuthService}');
  print('Theme Service: ${ThemeService}');
  print('Offline Storage Service: ${OfflineStorageService}');
  print('Performance Service: ${PerformanceService}');
}