import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  // دالة للتحقق من صحة البريد الإلكتروني
  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  void _resetPassword(BuildContext context) {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar(context, 'يرجى إدخال البريد الإلكتروني', Colors.red);
    } else if (!isValidEmail(email)) {
      _showSnackBar(context, 'يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
    } else {
      _showSnackBar(context, 'تم إرسال رابط إعادة تعيين كلمة المرور!', Colors.green);
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
