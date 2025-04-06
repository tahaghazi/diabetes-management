import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_/services/http_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  void _resetPassword(BuildContext context) async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(context, 'يرجى إدخال البريد الإلكتروني', Colors.red);
    } else if (!isValidEmail(email)) {
      _showSnackBar(context, 'يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
    } else {
      try {
        var response = await HttpService().makeRequest(
          method: 'POST',
          url: Uri.parse('http://127.0.0.1:8000/api/password_reset/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        );

        if (response == null) {
          _showSnackBar(context, 'حدث خطأ في الاتصال بالخادم', Colors.red);
          return;
        }

        if (response.statusCode == 200) {
          _showSnackBar(context, ' تم إرسال الكود بنجاح علي الايميل !', Colors.green);
        } else {
          _showSnackBar(context, 'حدث خطأ أثناء إرسال الكود', Colors.red);
        }
      } catch (e) {
        _showSnackBar(context, 'حدث خطأ في الاتصال بالخادم', Colors.red);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
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
      appBar: AppBar(title: Text('إعادة تعيين كلمة المرور')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _resetPassword(context),
              child: Text('إعادة تعيين كلمة المرور'),
            ),
          ],
        ),
      ),
    );
  }
}
