import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileAndSettingsScreenState createState() => _ProfileAndSettingsScreenState();
}

class _ProfileAndSettingsScreenState extends State<ProfileScreen> {
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;
  String? _medicalHistory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _firstName = prefs.getString('first_name');
        _lastName = prefs.getString('last_name');
        _email = prefs.getString('user_email');
        _accountType = prefs.getString('account_type');
        _specialization = prefs.getString('specialization');
        _medicalHistory = prefs.getString('medical_history') ?? 'غير متوفر';
      });
    } catch (e) {
      _showSnackBar('فشل تحميل البيانات: $e', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي '),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Container(
                    width: 300, // عرض الكارت
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue[900]!,
                          Colors.white,
                          Colors.blue[200]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                         
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _accountType == 'doctor'
                                    ? 'assets/images/doctor_logo.png.webp'
                                    : 'assets/images/patient_logo.png.webp',
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // الإيميل
                          Text(
                            _email ?? 'الإيميل',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          // الاسم
                          Text(
                            '${_firstName ?? 'الاسم'} ${_lastName ?? ''}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          // نوع الحساب
                          Text(
                            _accountType == 'doctor' ? 'دكتور' : 'مريض',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          // خط فاصل
                          Divider(
                            color: Colors.grey[400],
                            thickness: 1,
                          ),
                          const SizedBox(height: 15),
                          // التخصص أو السجل الصحي
                          if (_accountType == 'doctor')
                            Text(
                              'التخصص: ${_specialization ?? 'غير محدد'}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          if (_accountType == 'patient')
                            Text(
                              'السجل الصحي: ${_medicalHistory ?? 'غير متوفر'}',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 20),
                          // زر تعديل البيانات
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                              );
                              if (result == true) {
                                _loadUserData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'تعديل البيانات',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}