import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isObscure1 = true;
  bool _isObscure2 = true;

  String? _uidb64;
  String? _token;

  @override
  void initState() {
    super.initState();
    _getDeepLink();
  }

  // هذه الدالة لاستقبال الرابط
  Future<void> _getDeepLink() async {
    final appLink = await AppLinks().getInitialAppLink();
    if (appLink != null) {
      Uri uri = Uri.parse(appLink);
      setState(() {
        _uidb64 = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        _token = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      });
    }

    // التحقق من وجود رابط جديد أثناء استخدام التطبيق
    final latestAppLink = await AppLinks().getLatestAppLink();
    if (latestAppLink != null) {
      Uri uri = Uri.parse(latestAppLink);
      setState(() {
        _uidb64 = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        _token = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      });
    }
  }

  // هذه الدالة لإرسال الطلب إلى الـ API
  Future<void> _resetPassword() async {
    if (_uidb64 != null && _token != null) {
      final url = 'http://127.0.0.1:8000/api/password_reset/confirm/$_uidb64/$_token/'; // تعديل هنا
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'new_password': _newPasswordController.text,
          'confirm_new_password': _confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إعادة تعيين كلمة المرور بنجاح')),
        );
      } else {
        final responseBody = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['error'] ?? 'حدث خطأ')),
        );
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _resetPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إعادة تعيين كلمة المرور"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _isObscure1,
                decoration: InputDecoration(
                  labelText: "كلمة المرور الجديدة",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure1 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure1 = !_isObscure1;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "يرجى إدخال كلمة مرور جديدة";
                  }
                  if (value.length < 6) {
                    return "يجب أن تكون كلمة المرور على الأقل 6 أحرف";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isObscure2,
                decoration: InputDecoration(
                  labelText: "تأكيد كلمة المرور",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure2 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure2 = !_isObscure2;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return "كلمتا المرور غير متطابقتين";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("إعادة تعيين كلمة المرور"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
