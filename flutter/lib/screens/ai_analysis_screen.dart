import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart'; // استيراد الثيم

class AIAnalysisScreen extends StatelessWidget {
  const AIAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التنبؤ بمرض السكر',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient, // استخدام تدرج AppBar من الثيم
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient, // استخدام تدرج الخلفية من الثيم
          ),
          child: const Center(
            child: Text(
              'قيد التطوير...', // النص الأصلي
              style: TextStyle(fontSize: 20, color: Colors.teal),
            ),
          ),
        ),
      ),
    );
  }
}