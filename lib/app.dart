import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme.dart';

/// Racine de l'app 
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnostic Tourniquet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: DiagColors.title),
        scaffoldBackgroundColor: DiagColors.background,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
