import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'account_type_screen.dart';
import 'package:diabetes_management/services/http_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final String _apiUrl = 'http://10.0.2.2:8000/api/login/';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      setState(() {
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

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
      var response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: {'email': email, 'password': password},
      );

      if (response == null) {
        _showSnackBar('حدث خطأ أثناء الاتصال بالخادم', Colors.red);
        return;
      }

      var data = jsonDecode(utf8.decode(response.bodyBytes));

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String accessToken = data['access'];
        String refreshToken = data['refresh'];
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('user_email', data['user']['email']);
        await prefs.setString('account_type', data['user']['account_type']);
        await prefs.setString('first_name', data['user']['first_name']);
        await prefs.setString('last_name', data['user']['last_name']);
        await prefs.setString(
            'specialization', data['user']['specialization'] ?? '');
        await prefs.setString(
            'medical_history', data['user']['medical_history'] ?? '');

        HttpService().setTokens(accessToken, refreshToken);
        await _saveCredentials();

        _showSnackBar('تم تسجيل الدخول بنجاح!', Colors.green);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        }
      } else if (response.statusCode == 400) {
        var error = data['error'];
        if (error is List && error.isNotEmpty) {
          String errorMessage = error[0].toString().toLowerCase();
          if (errorMessage.contains('invalid email') || errorMessage.contains('user not found')) {
            _showSnackBar('هذا الحساب غير موجود، من فضلك أنشئ حسابًا', Colors.red);
          } else if (errorMessage.contains('password')) {
            _showSnackBar('كلمة المرور غير صحيحة', Colors.red);
          } else {
            _showSnackBar('حدث خطأ أثناء تسجيل الدخول', Colors.red);
          }
        } else {
          _showSnackBar('حدث خطأ أثناء تسجيل الدخول', Colors.red);
        }
      } else if (response.statusCode == 500) {
        _showSnackBar('حدث خطأ في الخادم، حاول لاحقًا', Colors.red);
      } else {
        _showSnackBar('حدث خطأ أثناء الاتصال بالخادم', Colors.red);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء الاتصال بالخادم', Colors.red);
      debugPrint("Error: $e");
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
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/logo_background.png.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '👋 مرحبًا!',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'قم بتسجيل الدخول إلى حسابك',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1.5),
                              ),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1.5),
                              ),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('تذكرني',
                                  style: Theme.of(context).textTheme.bodyMedium),
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _login,
                                  child: const Text('تسجيل الدخول'),
                                ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot_password');
                            },
                            child: const Text('هل نسيت كلمة المرور؟'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AccountTypeScreen()),
                              );
                            },
                            child: const Text('ليس لديك حساب؟ إنشاء حساب'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}