import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080A12),
  ));

  await Hive.initFlutter();
  await Hive.openBox<dynamic>('auth');
  await Hive.openBox<dynamic>('travel_cards');
  await Env.load();

  runApp(const ProviderScope(child: TripGraphApp()));
}
