import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool _codeVerified = false;
  bool _isLoading = false;

  String? _uidb64;
  String? _token;

  late AppLinks _appLinks;
  StreamSubscription<Uri?>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    try {
      // 1. الحصول على الرابط الأولي عند فتح التطبيق
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && mounted) {
        _handleDeepLink(initialUri);
      }

      // 2. الاستماع للروابط الجديدة أثناء استخدام التطبيق
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null && mounted) {
          _handleDeepLink(uri);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في معالجة الرابط: ${e.toString()}')),
        );
      }
    }
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    
    setState(() {
      _uidb64 = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      _token = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
    });
    
    if (_uidb64 != null && _token != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التعرف على رابط إعادة التعيين')),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكود يجب أن يكون 6 أرقام')),
      );
      return;
    }

    setState(() {
      _codeVerified = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم التحقق من الكود بنجاح')),
    );
  }

  Future<void> _resetPassword() async {
    if (!_codeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى التحقق من الكود أولاً')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمتا المرور غير متطابقتين')),
      );
      return;
    }

    if (_uidb64 == null || _token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط إعادة التعيين غير صالح')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/password_reset/confirm/$_uidb64/$_token/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'code': _codeController.text,
          'new_password': _newPasswordController.text,
          'confirm_new_password': _confirmPasswordController.text,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إعادة تعيين كلمة المرور بنجاح')),
          );
          Navigator.of(context).pop();
        } else {
          final responseBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['error'] ?? 'حدث خطأ أثناء إعادة التعيين')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في الاتصال: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!_codeVerified) {
        _verifyCode();
      } else {
        _resetPassword();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إعادة تعيين كلمة المرور"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!_codeVerified) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "أدخل الكود المكون من 6 أرقام الذي تلقيته عبر البريد الإلكتروني",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: "الكود",
                      border: OutlineInputBorder(),
                      counterText: "",
                      prefixIcon: Icon(Icons.code),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "يرجى إدخال الكود";
                      }
                      if (value.length != 6) {
                        return "يجب أن يكون الكود 6 أرقام";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("تحقق من الكود"),
                  ),
                  const SizedBox(height: 30),
                ],
                if (_codeVerified) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "الآن يمكنك إدخال كلمة المرور الجديدة",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _isObscure1,
                    decoration: InputDecoration(
                      labelText: "كلمة المرور الجديدة",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
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
                      prefixIcon: const Icon(Icons.lock_outline),
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
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator()
                        : const Text("إعادة تعيين كلمة المرور"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}