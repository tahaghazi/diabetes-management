import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'account_type_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final http.Client _client = http.Client();

  final String _apiUrl = 'http://127.0.0.1:8000/api/login/';

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validate the input
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى إدخال البريد الإلكتروني وكلمة المرور', Colors.red);
      return;
    } else if (!isValidEmail(email)) {
      _showSnackBar('يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
      return;
    } else if (password.length < 6) {
      _showSnackBar('يجب أن تكون كلمة المرور 6 أحرف أو أكثر', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await _client.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      var data = jsonDecode(utf8.decode(response.bodyBytes));

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // حفظ الـ tokens وبيانات المستخدم في SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('user_email', data['user']['email']);
        await prefs.setString('account_type', data['user']['account_type']);
        await prefs.setString('first_name', data['user']['first_name']);
        await prefs.setString('last_name', data['user']['last_name']);

        _showSnackBar('تم تسجيل الدخول بنجاح!', Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else if (response.statusCode == 401) {
        // Invalid credentials
        _showSnackBar(data['error'] ?? 'كلمة المرور أو البريد الإلكتروني غير صحيحة', Colors.red);
      } else if (response.statusCode == 400) {
        // Bad request
        _showSnackBar(data['error'] ?? 'حدث خطأ أثناء تسجيل الدخول', Colors.red);
      } else if (response.statusCode == 500) {
        // Server error
        _showSnackBar('حدث خطأ في الخادم، حاول لاحقًا', Colors.red);
      } else {
        // Other errors
        _showSnackBar('حدث خطأ أثناء الاتصال بالخادم', Colors.red);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء الاتصال بالخادم', Colors.red);
      print("Error: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تسجيل الدخول')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '👋 مرحبًا!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('تسجيل الدخول'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot_password');
              },
              child: Text('هل نسيت كلمة المرور؟'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountTypeScreen()),
                );
              },
              child: Text("ليس لديك حساب؟ إنشاء حساب"),
            ),
          ],
        ),
      ),
    );
  }
}
