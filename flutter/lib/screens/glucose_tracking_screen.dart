import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'previous_readings_screen.dart';

class GlucoseTrackingScreen extends StatefulWidget {
  const GlucoseTrackingScreen({super.key});

  @override
  GlucoseTrackingScreenState createState() => GlucoseTrackingScreenState();
}

class GlucoseTrackingScreenState extends State<GlucoseTrackingScreen> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _selectedReadingType = 'صائم';
  List<Map<String, dynamic>> glucoseReadings = [];
  DateTime? _selectedDateTime;
  final HttpService _httpService = HttpService();
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchReadings();
  }

  Future<void> _loadTokenAndFetchReadings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    if (accessToken != null) {
      setState(() {
        _token = accessToken;
      });
      _httpService.setTokens(accessToken, '');
      await _fetchGlucoseReadings();
    } else {
      _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
    }
  }

  Future<void> _fetchGlucoseReadings() async {
    if (_token == null) return;

    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('http://10.0.2.2:8000/api/glucose/list/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          setState(() {
            glucoseReadings = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        _showSnackBar('فشل في جلب القراءات!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل في جلب القراءات: $e', Colors.red);
    }
  }

  Future<void> _fetchMedicalHistory() async {
    if (_token == null) return;

    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('http://10.0.2.2:8000/api/profile/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String medicalHistory = responseData['medical_history'] ?? 'غير متوفر';
        await prefs.setString('medical_history', medicalHistory);
      } else {
        _showSnackBar('فشل في جلب السجل الصحي!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل في جلب السجل الصحي: $e', Colors.red);
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDateTime);
    final String formattedTime = DateFormat('h:mm a')
        .format(pickedDateTime)
        .replaceAll('AM', 'صباحًا')
        .replaceAll('PM', 'مساءً');

    if (!mounted) return;
    setState(() {
      _dateController.text = formattedDate;
      _timeController.text = formattedTime;
      _selectedDateTime = pickedDateTime;
    });
  }

  Future<void> _addGlucoseReading() async {
    if (_token == null) {
      _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      return;
    }

    if (_glucoseController.text.isNotEmpty &&
        _dateController.text.isNotEmpty &&
        _timeController.text.isNotEmpty &&
        _selectedDateTime != null) {
      try {
        double glucoseValue = double.parse(_glucoseController.text);
        // التحقق من أن القيمة بين 20 و600
        if (glucoseValue < 20 || glucoseValue > 600) {
          _showSnackBar('أدخل القياس الصحيح للسكر (بين 20 و600 mg/dL)!', Colors.red);
          return;
        }

        final Map<String, String> readingTypeMap = {
          'صائم': 'FBS',
          'عشوائي': 'RBS',
          'بعد الأكل': 'PPBS',
        };

        final String isoTimestamp = _selectedDateTime!.toUtc().toIso8601String();

        final body = {
          'glucose_type': readingTypeMap[_selectedReadingType]!,
          'glucose_value': glucoseValue,
          'timestamp': isoTimestamp,
        };

        final response = await _httpService.makeRequest(
          method: 'POST',
          url: Uri.parse('http://10.0.2.2:8000/api/glucose/add/'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response != null && response.statusCode == 201) {
          setState(() {
            _glucoseController.clear();
            _dateController.clear();
            _timeController.clear();
            _selectedDateTime = null;
          });

          _showSnackBar('تمت إضافة القراءة بنجاح!', Colors.green);
          await _fetchGlucoseReadings();
          await _fetchMedicalHistory();
        } else {
          _showSnackBar('فشل في إضافة القراءة!', Colors.red);
        }
      } catch (e) {
        _showSnackBar('فشل في إضافة القراءة: $e', Colors.red);
      }
    } else {
      _showSnackBar('يرجى ملء جميع الحقول!', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تتبع مستوى السكر',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PreviousReadingsScreen(readings: glucoseReadings),
                ),
              );
            },
            tooltip: 'القراءات السابقة',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'أدخل مستوى السكر',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _glucoseController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'مستوى السكر (mg/dL)',
                  prefixIcon: const Icon(Icons.monitor_heart),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      onTap: () => _selectDateTime(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'الوقت',
                        prefixIcon: const Icon(Icons.access_time),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      onTap: () => _selectDateTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedReadingType,
                items: ['صائم', 'عشوائي', 'بعد الأكل']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReadingType = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'نوع القراءة',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addGlucoseReading,
                child: const Text('حفظ القراءة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}