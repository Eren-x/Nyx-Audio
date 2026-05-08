import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/nyx_theme.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // macOS window sizing
  if (Platform.isMacOS) {
    // Size is set via macOS runner config; no extra package needed
  }

  runApp(
    const ProviderScope(
      child: NyxAudioApp(),
    ),
  );
}

class NyxAudioApp extends StatelessWidget {
  const NyxAudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyx Audio',
      debugShowCheckedModeBanner: false,
      theme: NyxTheme.theme,
      home: const AppShell(),
    );
  }
}
