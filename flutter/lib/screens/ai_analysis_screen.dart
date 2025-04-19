import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_management/config/theme.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  AIAnalysisScreenState createState() => AIAnalysisScreenState();
}

class AIAnalysisScreenState extends State<AIAnalysisScreen> {
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
    'Height': TextEditingController(),
    'Weight': TextEditingController(),
  };
  String? _result;
  String? _error;
  bool _isLoading = false;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _controllers['Height']!.addListener(_calculateBMI);
    _controllers['Weight']!.addListener(_calculateBMI);
  }

  void _calculateBMI() {
    final heightText = _controllers['Height']!.text;
    final weightText = _controllers['Weight']!.text;

    if (heightText.isNotEmpty && weightText.isNotEmpty) {
      final height = double.tryParse(heightText.replaceAll(',', '.'));
      final weight = double.tryParse(weightText.replaceAll(',', '.'));

      if (height != null && weight != null && height > 0) {
        final heightInMeters = height / 100;
        final bmi = weight / (heightInMeters * heightInMeters);
        _controllers['BMI']!.text = bmi.toStringAsFixed(1);
      }
    }
  }

  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _submitForm() async {
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
        // Prepare data for the API
        final data = {
          'Pregnancies': _selectedGender == 'Male' ? '0' : _controllers['Pregnancies']!.text,
          'Glucose': _controllers['Glucose']!.text.replaceAll(',', '.'),
          'BloodPressure': _controllers['BloodPressure']!.text.replaceAll(',', '.'),
          'SkinThickness': _controllers['SkinThickness']!.text.isEmpty
              ? '0'
              : _controllers['SkinThickness']!.text.replaceAll(',', '.'),
          'Insulin': _controllers['Insulin']!.text.isEmpty
              ? '0'
              : _controllers['Insulin']!.text.replaceAll(',', '.'),
          'BMI': _controllers['BMI']!.text.replaceAll(',', '.'),
          'DiabetesPedigreeFunction': _controllers['DiabetesPedigreeFunction']!.text.replaceAll(',', '.'),
          'Age': _controllers['Age']!.text.replaceAll(',', '.'),
        };

        // Print the data being sent for debugging
        print('Data being sent: $data');

        // Get the auth token
        final String? authToken = await _getAuthToken();
        if (authToken == null) {
          throw Exception('يرجى تسجيل الدخول أولاً');
        }

        // Make API request
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/api/predict/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode(data),
        );

        // Print the response details for debugging
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          String prediction = result['prediction'] ?? 'غير معروف';
          
          // Convert English prediction to Arabic if needed
          if (prediction.toLowerCase() == 'positive') {
            prediction = 'إيجابي';
          } else if (prediction.toLowerCase() == 'negative') {
            prediction = 'سلبي';
          }

          setState(() {
            _result = prediction;
          });
          _showSnackBar('تم التنبؤ بنجاح!', Colors.green);
        } else if (response.statusCode == 401) {
          throw Exception('فشل المصادقة: التوكن غير صالح. يرجى تسجيل الدخول مرة أخرى');
        } else {
          final error = jsonDecode(response.body)['error'] ?? 'حدث خطأ غير معروف';
          throw Exception(error);
        }
      } catch (e) {
        // Print the error for debugging
        print('Error: $e');
        setState(() {
          _error = e.toString();
        });
        _showSnackBar(e.toString(), Colors.red);
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
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.teal, fontFamily: 'Cairo'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 0.95),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        validator: (value) {
          if (!enabled) return null;
          if (value == null || value.isEmpty) {
            return 'يرجى إدخال $label';
          }
          final parsedValue = double.tryParse(value.replaceAll(',', '.'));
          if (parsedValue == null) {
            return 'يرجى إدخال رقم صالح (مثال: 1.5)';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الجنس',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGenderOption('Male', 'ذكر', 'assets/images/male.png.webp'),
                _buildGenderOption('Female', 'أنثى', 'assets/images/female.png.webp'),
              ],
            ),
          ],
        ),
      ),
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
          color: const Color.fromRGBO(0, 128, 0, 0.1),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(255, 0, 0, 0.1),
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
                fontFamily: 'Cairo',
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
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white, fontFamily: 'Cairo'),
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
            child: Column(
              children: [
                _buildGenderSelection(),
                const SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'من فضلك أدخل البيانات التالية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedGender == 'Female')
                            _buildTextField('عدد مرات الحمل', _controllers['Pregnancies']!),
                          _buildTextField('مستوى الجلوكوز', _controllers['Glucose']!),
                          _buildTextField('ضغط الدم', _controllers['BloodPressure']!),
                          _buildTextField('سمك الجلد', _controllers['SkinThickness']!),
                          _buildTextField('مستوى الأنسولين', _controllers['Insulin']!),
                          _buildTextField('الطول (سم)', _controllers['Height']!),
                          _buildTextField('الوزن (كجم)', _controllers['Weight']!),
                          _buildTextField('مؤشر كتلة الجسم', _controllers['BMI']!, enabled: false),
                          _buildTextField(
                              'عدد أفراد العائلة المصابين بالسكر', _controllers['DiabetesPedigreeFunction']!),
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}