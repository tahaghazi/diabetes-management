import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart'; // استيراد الثيم

class SignUpScreen extends StatefulWidget {
  final String accountType;

  const SignUpScreen({required this.accountType, super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse('http://10.0.2.2:8000/api/register/');
      var requestBody = {
        'email': _emailController.text.trim(),
        'password1': _passwordController.text.trim(),
        'password2': _confirmPasswordController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'account_type': widget.accountType,
      };

      if (widget.accountType == 'doctor') {
        requestBody['specialization'] = _specializationController.text.trim();
      }

      var response = await HttpService().makeRequest(
        method: 'POST',
        url: url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: requestBody,
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      var responseData = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint('Response: $responseData');

      if (response.statusCode == 201) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String accessToken = responseData['access'];
        String refreshToken = responseData['refresh'];
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('user_email', responseData['user']['email']);
        await prefs.setString('account_type', responseData['user']['account_type']);
        await prefs.setString('first_name', responseData['user']['first_name']);
        await prefs.setString('last_name', responseData['user']['last_name']);
        if (widget.accountType == 'doctor') {
          await prefs.setString('specialization', _specializationController.text.trim());
        }

        HttpService().setTokens(accessToken, refreshToken);
        _showSnackBar('تم إنشاء الحساب بنجاح!', Colors.green);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else if (response.statusCode == 400 && responseData.containsKey('email')) {
        _showSnackBar('البريد الإلكتروني مستخدم بالفعل', Colors.red);
      } else {
        _showSnackBar(responseData['error'] ?? 'حدث خطأ ما', Colors.red);
      }
    } catch (e) {
      debugPrint('Error: $e');
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إنشاء حساب',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'قم بإنشاء حسابك',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'الاسم الأول',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textDirection: TextDirection.rtl,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الاسم الأول';
                              }
                              if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value)) {
                                return 'الاسم الأول يجب أن يحتوي على حروف ومسافات فقط';
                              }
                              if (value.trim().isEmpty) {
                                return 'الاسم الأول لا يمكن أن يكون مسافات فقط';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'الاسم الأخير',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textDirection: TextDirection.rtl,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الاسم الأخير';
                              }
                              if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value)) {
                                return 'الاسم الأخير يجب أن يحتوي على حروف ومسافات فقط';
                              }
                              if (value.trim().isEmpty) {
                                return 'الاسم الأخير لا يمكن أن يكون مسافات فقط';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          if (widget.accountType == 'doctor')
                            Column(
                              children: [
                                TextFormField(
                                  controller: _specializationController,
                                  decoration: InputDecoration(
                                    labelText: 'التخصص',
                                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textDirection: TextDirection.rtl,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'يرجى إدخال التخصص';
                                    }
                                    if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(value)) {
                                      return 'التخصص يجب أن يحتوي على حروف ومسافات فقط';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'التخصص يجب أن يكون 3 حروف على الأقل';
                                    }
                                    if (value.trim().isEmpty) {
                                      return 'التخصص لا يمكن أن يكون مسافات فقط';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                              prefixIcon: const Icon(Icons.email),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textDirection: TextDirection.rtl,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال البريد الإلكتروني';
                              }
                              if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                                return 'البريد الإلكتروني غير صحيح';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textDirection: TextDirection.rtl,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال كلمة المرور';
                              }
                              if (value.length < 6) {
                                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.teal,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textDirection: TextDirection.rtl,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى تأكيد كلمة المرور';
                              }
                              if (value != _passwordController.text) {
                                return 'كلمتا المرور غير متطابقتين';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _register,
                                  child: Text(
                                    'إنشاء الحساب',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}