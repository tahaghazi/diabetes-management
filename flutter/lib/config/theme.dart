import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Colors.teal,
      scaffoldBackgroundColor: Colors.white, // خلفية بيضاء كاحتياط
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // شفاف للسماح للتدرج بالظهور
        foregroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 4, 192, 230), // تغيير لون النص إلى الأسود
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Colors.black, // تغيير لون النص إلى الأسود
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true, // تفعيل الخلفية
        fillColor: Colors.white70, // خلفية بيضاء خفيفة
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1), // خط خفيف لما البوكس مش متفعل
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 6), // خط أسمك وأوضح لما تفعّل البوكس
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        labelStyle: TextStyle(color: Colors.teal, fontSize: 14), // تصغير حجم الخط للـ label
        errorStyle: TextStyle(color: Colors.redAccent),
        floatingLabelBehavior: FloatingLabelBehavior.always, // الـ label يترفع دايمًا
        floatingLabelAlignment: FloatingLabelAlignment.start, // محاذاة الـ label لليمين (لأن الاتجاه RTL)
      ),
      cardTheme: const CardTheme(
        color: Colors.white, // تحديد لون خلفية Card إلى الأبيض
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  static const backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFE0F7FA), // لون سماوي فاتح
      Colors.white, // أبيض
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
    tileMode: TileMode.clamp,
  );

  static const appBarGradient = LinearGradient(
    colors: [Colors.teal, Colors.tealAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}