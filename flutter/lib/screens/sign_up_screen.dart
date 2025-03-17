import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  final String role;

  SignUpScreen({this.role = 'مريض'});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _accountType = '';
  bool _showSignUpForm = false;

  @override
  void initState() {
    super.initState();
    _accountType = widget.role == 'دكتور' ? 'doctor' : 'patient';
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

  void _signUp() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول', Colors.red);
    } else if (!isValidEmail(email)) {
      _showSnackBar('يرجى إدخال بريد إلكتروني صحيح', Colors.orange);
    } else if (password.length < 6) {
      _showSnackBar('يجب أن تكون كلمة المرور 6 أرقام أو أكثر', Colors.orange);
    } else if (password != confirmPassword) {
      _showSnackBar('كلمة المرور وتأكيدها غير متطابقين', Colors.red);
    } else {
      String accountTypeMessage = _accountType == 'patient' ? 'مريض' : 'دكتور';
      _showSnackBar('تم إنشاء الحساب بنجاح كـ $accountTypeMessage', Colors.green);

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    }
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

  void _goToSignUpForm() {
    if (_accountType.isEmpty) {
      _showSnackBar('يرجى تحديد نوع الحساب', Colors.red);
    } else {
      setState(() {
        _showSignUpForm = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إنشاء حساب')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_showSignUpForm) ...[
              // صندوق نوع الحساب
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'نوع الحساب',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 20),
                      // صندوق المريض والدكتور
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _accountType = 'patient';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _accountType == 'patient'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _accountType == 'patient'
                                        ? Colors.blue
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/patient_logo.png.webp', // مسار صورة المريض
                                      width: 60, // عرض الصورة
                                      height: 60, // ارتفاع الصورة
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'مريض',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _accountType == 'patient'
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _accountType = 'doctor';
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _accountType == 'doctor'
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _accountType == 'doctor'
                                        ? Colors.blue
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/doctor_logo.png.webp', // مسار صورة الدكتور
                                      width: 60, // عرض الصورة
                                      height: 60, // ارتفاع الصورة
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'دكتور',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _accountType == 'doctor'
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // زر التالي
              ElevatedButton(
                onPressed: _goToSignUpForm,
                child: Text(
                  'التالي',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ] else ...[
              // حقول إنشاء الحساب
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontSize: 16),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: Text(
                  'إنشاء الحساب',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}