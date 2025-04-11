import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  Future<void> _sendOTP() async {
    if (!mounted) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      if (mounted) {
        _showSnackBar('يرجى إدخال البريد الإلكتروني', Colors.red);
      }
      return;
    }

    if (!isValidEmail(email)) {
      if (mounted) {
        _showSnackBar('يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://10.0.2.2:8000/api/password_reset/'),
        headers: {'Content-Type': 'application/json'},
        body: {'email': email},
      );

      if (!mounted) return;

      if (response == null) {
        debugPrint('Response is null');
        _showSnackBar('فشل الاتصال بالخادم. تأكد من أن الخادم يعمل.', Colors.red);
        return;
      }

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _showSnackBar('تم إرسال الكود بنجاح على الإيميل!', Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email),
            ),
          );
        }
      } else {
        final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = responseBody['error'] ?? 'حدث خطأ أثناء إرسال الكود (كود الحالة: ${response.statusCode})';
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        _showSnackBar('حدث خطأ: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('إرسال الكود'),
            ),
          ],
        ),
      ),
    );
  }
}