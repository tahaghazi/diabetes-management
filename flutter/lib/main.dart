import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/glucose_tracking_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/alternative_medications_screen.dart';

void main() {
  runApp(DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diabetes Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/glucose_tracking': (context) => GlucoseTrackingScreen(),
        '/reminders': (context) => RemindersScreen(),
        '/ai_analysis': (context) => AIAnalysisScreen(),
        '/profile_settings': (context) => ProfileSettingsScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/sign_up': (context) => SignUpScreen(),
        '/chatbot': (context) => ChatbotScreen(),
        '/alternative_medications': (context) => AlternativeMedicationsScreen(),
      },
    );
  }
}
