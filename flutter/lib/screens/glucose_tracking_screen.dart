import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController _descriptionController = TextEditingController(); // للوصف
  String _selectedReadingType = 'صائم';
  List<Map<String, dynamic>> glucoseReadings = [];
  DateTime? _selectedDateTime;
  final HttpService _httpService = HttpService();
  String? _token;
  File? _selectedImage; // لتخزين الصورة المختارة
  bool _isUploading = false; // لتتبع حالة التحميل

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
      if (mounted) {
        _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      }
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
        if (mounted) {
          _showSnackBar('فشل في جلب القراءات!', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل في جلب القراءات: $e', Colors.red);
      }
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
        if (mounted) {
          _showSnackBar('فشل في جلب السجل الصحي!', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل في جلب السجل الصحي: $e', Colors.red);
      }
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
      if (mounted) {
        _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      }
      return;
    }

    if (_glucoseController.text.isNotEmpty &&
        _dateController.text.isNotEmpty &&
        _timeController.text.isNotEmpty &&
        _selectedDateTime != null) {
      try {
        double glucoseValue = double.parse(_glucoseController.text);
        if (glucoseValue < 20 || glucoseValue > 600) {
          if (mounted) {
            _showSnackBar('أدخل القياس الصحيح للسكر (بين 20 و600 mg/dL)!', Colors.red);
          }
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

          if (mounted) {
            _showSnackBar('تمت إضافة القراءة بنجاح!', Colors.green);
          }
          await _fetchGlucoseReadings();
          await _fetchMedicalHistory();
        } else {
          if (mounted) {
            _showSnackBar('فشل في إضافة القراءة!', Colors.red);
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('فشل في إضافة القراءة: $e', Colors.red);
        }
      }
    } else {
      if (mounted) {
        _showSnackBar('يرجى ملء جميع الحقول!', Colors.red);
      }
    }
  }

  // دالة لاختيار الصورة من المعرض مع طلب إذن الصور
  Future<void> _pickImage() async {
    var status = await Permission.photos.request();

    if (status.isGranted) {
      setState(() {
        _isUploading = true; // بدء التحميل
      });
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploading = false; // إنهاء التحميل
        });
      } else {
        setState(() {
          _isUploading = false; // إنهاء التحميل إذا لم يتم اختيار صورة
        });
      }
    } else if (status.isDenied) {
      if (mounted) {
        _showSnackBar('يرجى منح إذن الوصول إلى الصور!', Colors.red);
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        _showSnackBar('تم رفض الإذن بشكل دائم. يرجى تفعيله من إعدادات التطبيق.', Colors.red);
      }
      await openAppSettings();
    }
  }

  // دالة لإلغاء الصورة المختارة
  void _cancelImage() {
    setState(() {
      _selectedImage = null;
      _descriptionController.clear();
    });
    if (mounted) {
      _showSnackBar('تم إلغاء الصورة المختارة.', Colors.blue);
    }
  }

  // دالة لرفع الصورة إلى الـ API
  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      if (mounted) {
        _showSnackBar('يرجى اختيار صورة أولاً!', Colors.red);
      }
      return;
    }

    if (_token == null) {
      if (mounted) {
        _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      }
      return;
    }

    setState(() {
      _isUploading = true; // بدء التحميل
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/api/upload-analysis/'),
      );

      // إضافة رأس التوكن
      request.headers['Authorization'] = 'Bearer $_token';

      // إضافة الصورة
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ),
      );

      // إضافة الوصف إذا كان موجودًا
      if (_descriptionController.text.isNotEmpty) {
        request.fields['description'] = _descriptionController.text;
      }

      // إرسال الطلب
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        setState(() {
          _selectedImage = null;
          _descriptionController.clear();
        });
        if (mounted) {
          _showSnackBar('تم رفع الصورة بنجاح!', Colors.green);
        }
      } else if (response.statusCode == 400) {
        var errorData = jsonDecode(responseBody);
        if (mounted) {
          _showSnackBar('فشل في رفع الصورة: ${errorData['error']}', Colors.red);
        }
      } else if (response.statusCode == 403) {
        var errorData = jsonDecode(responseBody);
        if (mounted) {
          _showSnackBar('فشل في رفع الصورة: ${errorData['error']}', Colors.red);
        }
      } else {
        if (mounted) {
          _showSnackBar('فشل في رفع الصورة: خطأ غير معروف', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل في رفع الصورة: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false; // إنهاء التحميل
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان رفع تحاليل السكر
                Text(
                  'رفع تحاليل السكر',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                // كارد رفع الصورة
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // حقل الوصف
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'وصف الصورة (اختياري)',
                            prefixIcon: const Icon(Icons.description),
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
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        // زر اختيار الصورة مع مؤشر التحميل
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickImage,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.photo_library),
                            label: Text(_isUploading ? 'جارٍ التحميل...' : 'اختيار من المعرض'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // عرض الصورة المختارة
                        if (_selectedImage != null) ...[
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // زر إلغاء الصورة
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _cancelImage,
                              icon: const Icon(Icons.cancel),
                              label: const Text('إلغاء الصورة'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // زر رفع الصورة
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : _uploadImage,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.upload),
                              label: Text(_isUploading ? 'جارٍ الرفع...' : 'رفع الصورة'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // فاصل بين القسمين
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(
                    color: Color.fromARGB(255, 137, 150, 0),
                    thickness: 6,
                    indent: 20,
                    endIndent: 20,
                  ),
                ),
                // عنوان تسجيل قراءات السكر
                Text(
                  'تسجيل قراءات السكر',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // كارد تسجيل القراءة
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                onTap: () => _selectDateTime(context),
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
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _timeController,
                                readOnly: true,
                                onTap: () => _selectDateTime(context),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // زر حفظ القراءة خارج الكارد
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addGlucoseReading,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'حفظ القراءة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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