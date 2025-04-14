import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart'; // استيراد الثيم

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  String? _accountType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('first_name') ?? '';
      _lastNameController.text = prefs.getString('last_name') ?? '';
      _specializationController.text = prefs.getString('specialization') ?? '';
      _medicalHistoryController.text = prefs.getString('medical_history') ?? '';
      _accountType = prefs.getString('account_type');
    });

    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');
    if (accessToken != null && refreshToken != null) {
      HttpService().setTokens(accessToken, refreshToken);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      var requestBody = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
      };

      if (_accountType == 'doctor') {
        requestBody['specialization'] = _specializationController.text.trim();
      } else if (_accountType == 'patient') {
        requestBody['medical_history'] = _medicalHistoryController.text.trim();
      }

      var response = await HttpService().makeRequest(
        method: 'PUT',
        url: Uri.parse('http://10.0.2.2:8000/api/update-profile/'),
        //url: Uri.parse('http://127.0.0.1:8000/api/update-profile/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (!mounted) return;

      if (response == null) {
        _showSnackBar('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى', Colors.red);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      if (response.statusCode == 200) {
        await prefs.setString('first_name', _firstNameController.text.trim());
        await prefs.setString('last_name', _lastNameController.text.trim());
        if (_accountType == 'doctor') {
          await prefs.setString('specialization', _specializationController.text.trim());
        } else if (_accountType == 'patient') {
          await prefs.setString('medical_history', _medicalHistoryController.text.trim());
        }

        _showSnackBar('تم تحديث البيانات بنجاح!', Colors.green);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        var responseData = jsonDecode(response.body);
        _showSnackBar(responseData['message'] ?? 'حدث خطأ أثناء تحديث البيانات', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancel() {
    Navigator.pop(context);
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
            'تعديل الملف الشخصي',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient, // استخدام تدرج AppBar من الثيم
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient, // استخدام تدرج الخلفية من الثيم
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 40, right: 16, left: 16, bottom: 16),
            child: Form(
              key: _formKey,
              child: SizedBox(
                height: MediaQuery.of(context).size.height, // تحديد الارتفاع بناءً على حجم الشاشة
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'الاسم الأول',
                            labelStyle: Theme.of(context).textTheme.bodyMedium,
                            border: const OutlineInputBorder(),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'الاسم الأخير',
                            labelStyle: Theme.of(context).textTheme.bodyMedium,
                            border: const OutlineInputBorder(),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
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
                        const SizedBox(height: 16),
                        if (_accountType == 'doctor')
                          TextFormField(
                            controller: _specializationController,
                            decoration: InputDecoration(
                              labelText: 'التخصص',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                              border: const OutlineInputBorder(),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
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
                        if (_accountType == 'patient')
                          TextFormField(
                            controller: _medicalHistoryController,
                            decoration: InputDecoration(
                              labelText: 'السجل الصحي',
                              labelStyle: Theme.of(context).textTheme.bodyMedium,
                              border: const OutlineInputBorder(),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[\p{L}\s\d\u0660-\u0669\-\/.,]*$', unicode: true).hasMatch(value)) {
                                  return 'السجل الصحي يجب أن يحتوي على حروف وأرقام فقط';
                                }
                                if (value.trim().isEmpty) {
                                  return 'السجل الصحي لا يمكن أن يكون مسافات فقط';
                                }
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _updateProfile,
                                    child: Text(
                                      'حفظ التعديلات',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _cancel,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[400],
                                    ),
                                    child: Text(
                                      'إلغاء',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
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
    );
  }
}