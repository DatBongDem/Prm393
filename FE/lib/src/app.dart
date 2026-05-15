import 'package:fe/src/core/theme/app_theme.dart';
import 'package:fe/src/feature/grade_ui/presentation/grade_management_page.dart';
import 'package:flutter/material.dart';

class GradeDestopApp extends StatelessWidget {
  const GradeDestopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Student Grade Management",
      theme: AppTheme.light(),
      home: const GradeManagementPage(),
    );
  }
}
