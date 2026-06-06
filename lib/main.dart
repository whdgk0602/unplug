import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project001/app.dart';
import 'package:project001/data/database/app_database.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await AppDatabase.instance.initialize();

  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: UnplugApp()));
}
