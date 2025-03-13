import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'glucose_tracking_screen.dart';
import 'reminders_screen.dart';
import 'chatbot_screen.dart';
import 'alternative_medications_screen.dart';
import 'ai_analysis_screen.dart';
import 'profile_settings_screen.dart';


class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصفحة الرئيسة'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue),
            onPressed: () {
              // تسجيل الخروج وإعادة المستخدم إلى شاشة تسجيل الدخول
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false, // إزالة جميع الشاشات السابقة من المكدس
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildDashboardButton(
              context,
              title: 'تتبع مستوى السكر',
              icon: Icons.show_chart,
              screen: GlucoseTrackingScreen(),
            ),
            _buildDashboardButton(
              context,
              title: 'التذكيرات',
              icon: Icons.medical_services,
              screen: RemindersScreen(),
            ),
            _buildDashboardButton(
              context,
              title: 'الشات بوت',
              icon: Icons.chat,
              screen: ChatbotScreen(),
            ),
            _buildDashboardButton(
              context,
              title: 'الأدوية البديلة',
              icon: Icons.local_pharmacy,
              screen: AlternativeMedicationsScreen(),
            ),
            _buildDashboardButton(
              context,
              title: 'التنبؤ ب مرض السكر',
              icon: Icons.analytics,
              screen: AIAnalysisScreen(),
            ),
            _buildDashboardButton(
              context,
              title: 'الملف الشخصي والإعدادات',
              icon: Icons.person,
              screen: ProfileSettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context, {required String title, required IconData icon, required Widget screen}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
