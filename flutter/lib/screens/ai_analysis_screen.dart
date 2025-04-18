import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  _AIAnalysisScreenState createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'Pregnancies': TextEditingController(),
    'Glucose': TextEditingController(),
    'BloodPressure': TextEditingController(),
    'SkinThickness': TextEditingController(),
    'Insulin': TextEditingController(),
    'BMI': TextEditingController(),
    'DiabetesPedigreeFunction': TextEditingController(),
    'Age': TextEditingController(),
  };
  String? _result;
  String? _error;
  bool _isLoading = false;
  String? _selectedGender;
  String? _token;
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken != null) {
      setState(() {
        _token = accessToken;
      });
      _httpService.setTokens(accessToken, '');
    } else {
      _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
    }
  }

  Future<void> _submitForm() async {
    if (_token == null) {
      _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      return;
    }

    if (_selectedGender == null) {
      _showSnackBar('يرجى اختيار الجنس أولاً!', Colors.red);
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
        _result = null;
      });

      try {
        final Map<String, dynamic> data = {};
        _controllers.forEach((key, controller) {
          if (key == 'Pregnancies' && _selectedGender == 'Male') {
            data[key] = '0'; // Set Pregnancies to 0 for males
          } else {
            data[key] = controller.text;
          }
        });

        final response = await _httpService.makeRequest(
          method: 'POST',
          url: Uri.parse('http://10.0.2.2:8000/api/predict/'),
          headers: {'Content-Type': 'application/json'},
          body: data,
        );

        if (response != null && response.statusCode == 200) {
          final result = jsonDecode(response.body);
          setState(() {
            _result = result['prediction']?.toString() ?? 'تم التنبؤ بنجاح';
          });
          _showSnackBar('تم التنبؤ بنجاح!', Colors.green);
        } else {
          final error = response != null
              ? jsonDecode(response.body)['error'] ?? 'حدث خطأ'
              : 'فشل الاتصال بالخادم';
          setState(() {
            _error = error;
          });
          _showSnackBar('خطأ: $error', Colors.red);
        }
      } catch (e) {
        setState(() {
          _error = 'فشل في التنبؤ: $e';
        });
        _showSnackBar('فشل في التنبؤ: $e', Colors.red);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.teal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.95),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (!enabled) return null;
          if (value == null || value.isEmpty) {
            return 'يرجى إدخال $label';
          }
          if (double.tryParse(value) == null) {
            return 'يرجى إدخال رقم صالح (مثال: 1.5)';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر الجنس',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildGenderOption('Male', 'ذكر', 'assets/male.png'),
            _buildGenderOption('Female', 'أنثى', 'assets/female.png'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, String label, String imagePath) {
    bool isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
          if (gender == 'Male') {
            _controllers['Pregnancies']!.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person,
                size: 80,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التنبؤ بمرض السكر',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient,
            ),
          ),
          elevation: 4,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGenderSelection(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        'عدد مرات الحمل',
                        _controllers['Pregnancies']!,
                        enabled: _selectedGender == 'Female',
                      ),
                      _buildTextField('مستوى الجلوكوز', _controllers['Glucose']!),
                      _buildTextField('ضغط الدم', _controllers['BloodPressure']!),
                      _buildTextField('سمك الجلد', _controllers['SkinThickness']!),
                      _buildTextField('مستوى الأنسولين', _controllers['Insulin']!),
                      _buildTextField('مؤشر كتلة الجسم', _controllers['BMI']!),
                      _buildTextField('وظيفة نسب السكري', _controllers['DiabetesPedigreeFunction']!),
                      _buildTextField('العمر', _controllers['Age']!),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading || _selectedGender == null ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'إرسال',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 20),
                      if (_result != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'النتيجة: $_result',
                            style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'خطأ: $_error',
                            style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
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
    );
  }
}