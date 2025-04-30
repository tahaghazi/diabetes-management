import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'full_image_screen.dart';

class PatientHealthRecordScreen extends StatefulWidget {
  final int patientId;

  const PatientHealthRecordScreen({super.key, required this.patientId});

  @override
  PatientHealthRecordScreenState createState() => PatientHealthRecordScreenState();
}

class PatientHealthRecordScreenState extends State<PatientHealthRecordScreen> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _healthRecord;
  String? _errorMessage;
  bool _isLoading = true;
  String? _token;
  final HttpService _httpService = HttpService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      if (accessToken != null) {
        setState(() {
          _token = accessToken;
        });
        _httpService.setTokens(accessToken, '');
        await _fetchPatientHealthRecord();
      } else {
        setState(() {
          _errorMessage = 'لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatientHealthRecord() async {
    debugPrint('Starting fetch health record for patient ID: ${widget.patientId}');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Sending request to fetch patient health record');
      final healthResponse = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/patient-health-record/${widget.patientId}/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('تجاوز مهلة جلب السجل المرضي');
      });

      if (healthResponse == null) {
        throw Exception('فشل الاتصال بالسيرفر');
      }

      debugPrint('Patient Health Record Response Status: ${healthResponse.statusCode}');
      debugPrint('Patient Health Record Response Body: ${healthResponse.body}');

      if (healthResponse.statusCode == 200) {
        debugPrint('Parsing health record response');
        final healthData = jsonDecode(utf8.decode(healthResponse.bodyBytes));
        healthData['full_name'] = '${healthData['first_name'] ?? 'غير متوفر'} ${healthData['last_name'] ?? ''}'.trim();

        // Fetch patient analysis
        debugPrint('Fetching patient analysis');
        List<Map<String, dynamic>> analysisData = [];
        try {
          analysisData = await _fetchPatientAnalysis(widget.patientId);
        } catch (e) {
          debugPrint('Failed to fetch analysis, proceeding with health record: $e');
        }
        healthData['analysis'] = analysisData;

        debugPrint('Health record data prepared: $healthData');
        setState(() {
          _healthRecord = healthData;
          _isLoading = false;
        });
      } else {
        final responseData = jsonDecode(healthResponse.body);
        throw Exception(responseData['error'] ?? 'فشل تحميل السجل المرضي: ${healthResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch Health Record Error: $e');
      setState(() {
        _errorMessage = 'حدث خطأ أثناء جلب السجل المرضي: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPatientAnalysis(int patientId) async {
    debugPrint('Fetching analysis for patient ID: $patientId');
    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/patient-analysis/$patientId/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('تجاوز مهلة جلب تحاليل المريض');
      });

      if (response == null) {
        throw Exception('فشل الاتصال بالسيرفر');
      }

      debugPrint('Patient Analysis Response Status: ${response.statusCode}');
      debugPrint('Patient Analysis Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['error'] ?? 'فشل جلب تحاليل المريض: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Fetch Patient Analysis Error: $e');
      throw Exception('حدث خطأ أثناء جلب تحاليل المريض: $e');
    }
  }

  Future<void> _addCommentToAnalysis(int analysisId, String comment) async {
    if (_token == null) {
      _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      return;
    }

    try {
      final response = await _httpService.makeRequest(
        method: 'POST',
        url: Uri.parse('http://192.168.100.6:8000/api/add-comment-to-analysis/$analysisId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment': comment}),
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      debugPrint('Add Comment Response Status: ${response.statusCode}');
      debugPrint('Add Comment Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _showSnackBar('تم إضافة التعليق بنجاح!', Colors.green);
        await _fetchPatientHealthRecord(); // Refresh data to update the table
      } else {
        final responseData = jsonDecode(response.body);
        _showSnackBar(responseData['error'] ?? 'فشل في إضافة التعليق!', Colors.red);
      }
    } catch (e) {
      debugPrint('Add Comment Error: $e');
      _showSnackBar('فشل في إضافة التعليق: $e', Colors.red);
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

  Future<void> _showCommentDialog(int analysisId) async {
    final TextEditingController commentController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تعليق'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: 'اكتب تعليقك هنا',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              if (commentController.text.trim().isEmpty) {
                _showSnackBar('التعليق لا يمكن أن يكون فارغًا', Colors.red);
                return;
              }
              Navigator.pop(context);
              _addCommentToAnalysis(analysisId, commentController.text.trim());
            },
            child: const Text('إرسال', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _translateMedicalHistory(String? medicalHistory) {
    debugPrint('Translating medical history: $medicalHistory');
    try {
      if (medicalHistory == null || medicalHistory.isEmpty) {
        debugPrint('Medical history is null or empty');
        return [
          {
            'type': '',
            'value': 'لا يوجد تاريخ مرضي',
            'date': '',
            'time': '',
          }
        ];
      }

      const glucoseTypeMap = {
        'Postprandial Blood Sugar': 'بعد الأكل',
        'Random Blood Sugar': 'عشوائي',
        'Fasting Blood Sugar': 'صائم',
      };

      List<String> lines = medicalHistory.split('\n');
      List<Map<String, String>> translatedRecords = [];
      const int maxRecords = 50; // Limit to prevent performance issues

      debugPrint('Processing ${lines.length} lines of medical history');
      for (String line in lines.take(maxRecords)) {
        line = line.trim();
        debugPrint('Processing line: $line');

        if (line.toLowerCase().contains('glucose readings')) {
          debugPrint('Skipping glucose readings header');
          continue;
        }

        RegExp regExp = RegExp(r'-\s*(.+?):\s*(\d+\.\d+|\d+)\s*mg/dL\s*on\s*(\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2}(?::\d{2})?)');
        var match = regExp.firstMatch(line);

        if (match != null) {
          String glucoseType = match.group(1) ?? '';
          String glucoseValue = match.group(2) ?? '0';
          String dateTimeStr = match.group(3) ?? '';

          String translatedType = glucoseTypeMap[glucoseType] ?? glucoseType;
          debugPrint('Matched: type=$glucoseType, value=$glucoseValue, date=$dateTimeStr');

          dateTimeStr = dateTimeStr.trim();

          try {
            DateTime dateTime = DateTime.parse(dateTimeStr);
            String date = '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
            String time = DateFormat('h:mm a')
                .format(dateTime)
                .replaceAll('AM', 'صباحاً')
                .replaceAll('PM', 'مساءً');

            translatedRecords.add({
              'type': translatedType,
              'value': '$glucoseValue mg/dL',
              'date': date,
              'time': time,
            });
            debugPrint('Added record: $translatedRecords.last');
          } catch (e) {
            debugPrint('Error parsing date in medical history: $e');
            translatedRecords.add({
              'type': translatedType,
              'value': '$glucoseValue mg/dL',
              'date': dateTimeStr,
              'time': '',
            });
          }
        } else {
          debugPrint('No match for line: $line');
        }
      }

      if (translatedRecords.isEmpty) {
        debugPrint('No records translated');
        return [
          {
            'type': '',
            'value': 'لا يوجد تاريخ مرضي',
            'date': '',
            'time': '',
          }
        ];
      }

      debugPrint('Translated ${translatedRecords.length} records');
      return translatedRecords;
    } catch (e) {
      debugPrint('Error in translateMedicalHistory: $e');
      return [
        {
          'type': '',
          'value': 'خطأ في معالجة السجل المرضي',
          'date': '',
          'time': '',
        }
      ];
    }
  }

  Widget _buildHealthRecordItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('السجل المرضي'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTokenAndFetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _healthRecord == null
                    ? Center(
                        child: Text(
                          'لا يوجد سجل مرضي متاح',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHealthRecordItem(
                                    context,
                                    'الاسم الكامل',
                                    _healthRecord!['full_name'] ?? 'غير متوفر',
                                  ),
                                  const Divider(color: Colors.teal, thickness: 0.5),
                                  _buildHealthRecordItem(
                                    context,
                                    'البريد الإلكتروني',
                                    _healthRecord!['email'] ?? 'غير متوفر',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            color: Colors.teal,
                            thickness: 1.0,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سجل مستوي السكر في الدم',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  border: TableBorder(
                                    horizontalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                                    verticalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                                    top: BorderSide(width: 1, color: Colors.grey.shade300),
                                    bottom: BorderSide(width: 1, color: Colors.grey.shade300),
                                    left: BorderSide(width: 1, color: Colors.grey.shade300),
                                    right: BorderSide(width: 1, color: Colors.grey.shade300),
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'نوع القياس',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'مستوي السكر',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'التوقيت',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: _translateMedicalHistory(_healthRecord!['medical_history']).map((record) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            record['type'] ?? '',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            record['value'] ?? '',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                ),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record['date'] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.black87,
                                                      fontSize: 16,
                                                    ),
                                              ),
                                              Text(
                                                record['time'] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Colors.black87,
                                                      fontSize: 16,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  columnSpacing: 20,
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 70,
                                  headingRowColor: WidgetStateProperty.all(Colors.teal.shade100),
                                  dividerThickness: 1,
                                  showBottomBorder: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(
                            color: Colors.teal,
                            thickness: 1.0,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تحاليل السكر',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط على الأيقونة لعرض صورة التحليل',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _healthRecord!['analysis'].isEmpty
                              ? Center(
                                  child: Text(
                                    'لا توجد تحاليل متاحة',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                )
                              : Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.teal[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: RepaintBoundary(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          border: TableBorder(
                                            horizontalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                                            verticalInside: BorderSide(width: 1, color: Colors.grey.shade300),
                                            top: BorderSide(width: 1, color: Colors.grey.shade300),
                                            bottom: BorderSide(width: 1, color: Colors.grey.shade300),
                                            left: BorderSide(width: 1, color: Colors.grey.shade300),
                                            right: BorderSide(width: 1, color: Colors.grey.shade300),
                                          ),
                                          columns: const [
                                            DataColumn(
                                              label: Text(
                                                'تحليل السكر',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'الوصف',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'تاريخ الرفع',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                'تعليق الدكتور',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                          rows: _healthRecord!['analysis'].map<DataRow>((imageData) {
                                            final int analysisId = imageData['id'] ?? 0;
                                            final String imageUrl = imageData['image'] ?? '';
                                            final String description = imageData['description'] ?? 'بدون وصف';
                                            final String comment = imageData['comment'] ?? 'لا يوجد تعليق';
                                            final String uploadedAt = imageData['uploaded_at'] ?? DateTime.now().toString();
                                            DateTime uploadDate;
                                            try {
                                              uploadDate = DateTime.parse(uploadedAt);
                                            } catch (e) {
                                              debugPrint('Error parsing uploaded_at: $e');
                                              uploadDate = DateTime.now();
                                            }
                                            final String formattedDate = DateFormat('yyyy-MM-dd').format(uploadDate);

                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  GestureDetector(
                                                    onTap: imageUrl.isEmpty || kIsWeb
                                                        ? null
                                                        : () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => FullImageScreen(
                                                                  imageUrl: 'http://192.168.100.6:8000$imageUrl',
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                    child: Container(
                                                      height: 45,
                                                      width: 45,
                                                      decoration: BoxDecoration(
                                                        color: Colors.teal.shade100,
                                                        borderRadius: BorderRadius.circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black12,
                                                            blurRadius: 4,
                                                            offset: const Offset(2, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 35,
                                                        color: imageUrl.isEmpty || kIsWeb ? Colors.grey : Colors.teal.shade800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    description,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          color: Colors.black87,
                                                          fontSize: 16,
                                                        ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    formattedDate,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          color: Colors.black87,
                                                          fontSize: 16,
                                                        ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          comment,
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                color: comment == 'لا يوجد توصية' ? Colors.grey[600] : Colors.black87,
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.comment, color: Colors.teal),
                                                        tooltip: 'إرسال توصية ',
                                                        onPressed: () {
                                                          _showCommentDialog(analysisId);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                          columnSpacing: 20,
                                          dataRowMinHeight: 50,
                                          dataRowMaxHeight: 70,
                                          headingRowColor: WidgetStateProperty.all(Colors.teal.shade100),
                                          dividerThickness: 1,
                                          showBottomBorder: true,
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