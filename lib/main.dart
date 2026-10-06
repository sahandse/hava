import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/app.dart';
import 'package:hava/core/services/background_service.dart';
import 'package:hava/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await BackgroundService.initialize();
  runApp(const ProviderScope(child: HavaApp()));
}
