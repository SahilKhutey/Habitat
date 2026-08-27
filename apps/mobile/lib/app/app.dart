// Phase 1 Root Application Widget
import 'package:flutter/material.dart';
import '../core/theme/habitat_theme.dart';
import '../features/foundation/presentation/foundation_screen.dart';

class DisciplineApp extends StatelessWidget {
  const DisciplineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discipline',
      debugShowCheckedModeBanner: false,
      theme: HabitatTheme.darkTheme,
      home: const FoundationScreen(),
    );
  }
}
