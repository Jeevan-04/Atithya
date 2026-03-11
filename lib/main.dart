// =============================================================================
// आतिथ्य — Royal Hospitality Platform
// Author : Jeevan Naidu <jeevannaidu04@gmail.com>
// GitHub : https://github.com/Jeevan-04
// License: Proprietary © 2025-2026 Jeevan Naidu. All rights reserved.
// -----------------------------------------------------------------------------
// Entry point — bootstraps Flutter engine, forces portrait lock on mobile,
// and mounts the Riverpod ProviderScope over SplashScreen.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Absolute full screen, pure black bars
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(
      const ProviderScope(
        child: AtithyaApp(),
      ),
    );
  });
}

class AtithyaApp extends StatelessWidget {
  const AtithyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'आतिथ्य | ATITHYA',
      debugShowCheckedModeBanner: false,
      theme: AtithyaTheme.darkTheme,
      home: const SplashScreen(), // Starts the V3 sequence
    );
  }
}
