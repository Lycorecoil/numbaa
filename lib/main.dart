import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/di/service_locator.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode (mobile-first)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Register all dependencies
  setupServiceLocator();

  runApp(const NumbiaApp());
}
