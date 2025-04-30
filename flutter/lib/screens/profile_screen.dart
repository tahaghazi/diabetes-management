import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../main.dart';
import 'package:intl/intl.dart';
import 'full_image_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileAndSettingsScreenState createState() => ProfileAndSettingsScreenState();
}

class ProfileAndSettingsScreenState extends State<ProfileScreen> with RouteAware, WidgetsBindingObserver {
  bool _isLoading = false;
  Map<String, dynamic>? _linkedDoctor;
  List<Map<String, dynamic>> _glucoseReadings = [];
  List<Map<String, dynamic>> _analysisImages = [];
  String? _token;
  final HttpService _httpService = HttpService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTokenAndFetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('ProfileScreen: didPopNext called, refreshing data...');
    _loadTokenAndFetchData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('ProfileScreen: App resumed, refreshing data...');
      _loadTokenAndFetchData();
    }
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
        await _loadUserData();
        if (Provider.of<UserProvider>(context, listen: false).accountType == 'patient') {
          await _fetchGlucoseReadings();
          await _fetchAnalysisImages();
        }
      } else {
        _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل تحميل البيانات: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/profile/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
      );

      if (response == null) {
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        Provider.of<UserProvider>(context, listen: false).updateUser(
          email: responseData['email'],
          firstName: responseData['first_name'],
          lastName: responseData['last_name'],
          accountType: responseData.containsKey('medical_history')
              ? 'patient'
              : responseData.containsKey('specialization')
                  ? 'doctor'
                  : null,
          specialization: responseData.containsKey('specialization') ? responseData['specialization'] ?? 'غير محدد' : null,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('first_name', responseData['first_name'] ?? '');
        await prefs.setString('last_name', responseData['last_name'] ?? '');
        await prefs.setString('user_email', responseData['email'] ?? '');
        await prefs.setString(
          'account_type',
          responseData.containsKey('medical_history')
              ? 'patient'
              : responseData.containsKey('specialization')
                  ? 'doctor'
                  : '',
        );
        if (responseData.containsKey('specialization')) {
          await prefs.setString('specialization', responseData['specialization'] ?? '');
        }

        if (Provider.of<UserProvider>(context, listen: false).accountType == 'patient') {
          await _fetchLinkedDoctor();
        }
      } else {
        _showSnackBar('فشل جلب بيانات الملف الشخصي', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل تحميل البيانات: $e', Colors.red);
    }
  }

  Future<void> _fetchLinkedDoctor() async {
    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/my-doctor/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
      );

      if (response == null) {
        debugPrint('Fetch Linked Doctor: Response is null');
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      debugPrint('My Doctor API Response Status: ${response.statusCode}');
      debugPrint('My Doctor API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('Parsed Response Data: $responseData');

        setState(() {
          if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
            _linkedDoctor = null;
            debugPrint('No linked doctor found');
          } else if (responseData is Map<String, dynamic>) {
            _linkedDoctor = responseData;
            debugPrint('Linked doctor set: $_linkedDoctor');
          } else {
            _linkedDoctor = null;
            debugPrint('Unexpected response format');
          }
        });
      } else {
        debugPrint('Fetch Linked Doctor: Status code ${response.statusCode}');
        _showSnackBar('فشل جلب بيانات الدكتور المرتبط', Colors.red);
      }
    } catch (e) {
      debugPrint('Fetch Linked Doctor Error: $e');
      _showSnackBar('حدث خطأ: $e', Colors.red);
    }
  }

  Future<void> _fetchGlucoseReadings() async {
    if (_token == null) return;

    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/glucose/list/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
      );

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseData['data'] != null) {
          setState(() {
            _glucoseReadings = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      } else {
        _showSnackBar('فشل في جلب قياسات السكر!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل في جلب قياسات السكر: $e', Colors.red);
    }
  }

  Future<void> _fetchAnalysisImages() async {
    if (_token == null) return;

    try {
      final response = await _httpService.makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/my-analysis/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
      );

      if (response != null && response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseData['data'] != null) {
          setState(() {
            _analysisImages = List<Map<String, dynamic>>.from(responseData['data']);
            for (var image in _analysisImages) {
              debugPrint('Description: ${image['description']}');
            }
          });
        }
      } else {
        _showSnackBar('فشل في جلب تحاليل السكر!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('فشل في جلب تحاليل السكر: $e', Colors.red);
    }
  }

  Future<void> _deleteAnalysis(int analysisId) async {
    debugPrint('Attempting to delete analysis with ID: $analysisId');
    if (_token == null) {
      debugPrint('No token found');
      _showSnackBar('لم يتم العثور على رمز الوصول! يرجى تسجيل الدخول.', Colors.red);
      return;
    }

    try {
      debugPrint('Sending DELETE request to: http://192.168.100.6:8000/api/delete-analysis/$analysisId/');
      final response = await _httpService.makeRequest(
        method: 'DELETE',
        url: Uri.parse('http://192.168.100.6:8000/api/delete-analysis/$analysisId/'),
        
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('Delete Analysis Response Status: ${response?.statusCode}');
      debugPrint('Delete Analysis Response Body: ${response?.body}');

      if (response != null && response.statusCode == 200) {
        setState(() {
          _analysisImages.removeWhere((image) => image['id'] == analysisId);
        });
        _showSnackBar('تم حذف التحليل بنجاح!', Colors.green);
      } else {
        final responseData = response != null ? jsonDecode(utf8.decode(response.bodyBytes)) : {};
        debugPrint('Response Data: $responseData');
        _showSnackBar(
          responseData['error'] ?? 'فشل في حذف التحليل!',
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint('Delete Analysis Error: $e');
      _showSnackBar('فشل في حذف التحليل: $e', Colors.red);
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(int analysisId) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'هل أنت متأكد من حذف هذا التحليل؟ لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.teal),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<Map<String, dynamic>> _parseGlucoseReadings() {
    const glucoseTypeMap = {
      'FBS': 'صائم',
      'RBS': 'عشوائي',
      'PPBS': 'بعد الأكل',
    };

    return _glucoseReadings.map((reading) {
      return {
        'id': reading['id']?.toString() ?? '',
        'type': glucoseTypeMap[reading['glucose_type']] ?? reading['glucose_type']?.toString() ?? '',
        'level': reading['glucose_value']?.toString() ?? '',
        'dateTime': reading['timestamp']?.toString() ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'الملف الشخصي',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.appBarGradient,
              ),
            ),
            elevation: 4,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadTokenAndFetchData,
                tooltip: 'تحديث البيانات',
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.teal, width: 3),
                                    ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.white,
                                      backgroundImage: AssetImage(
                                        userProvider.accountType == 'doctor'
                                            ? 'assets/images/doctor_logo.png.webp'
                                            : 'assets/images/patient_logo.png.webp',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${userProvider.firstName ?? 'الاسم'} ${userProvider.lastName ?? ''}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.teal.shade900,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    userProvider.email ?? 'الإيميل',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[700],
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    userProvider.accountType == 'doctor' ? 'دكتور' : 'مريض',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(
                                    color: Colors.grey[300],
                                    thickness: 1.5,
                                  ),
                                  const SizedBox(height: 16),
                                  if (userProvider.accountType == 'patient')
                                    _linkedDoctor != null
                                        ? Container(
                                            constraints: BoxConstraints(
                                              minWidth: 300,
                                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                                            ),
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.teal, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.teal.shade50,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'الدكتور المعالج',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        color: Colors.teal.shade800,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${_linkedDoctor!['first_name'] ?? 'غير متوفر'} ${_linkedDoctor!['last_name'] ?? ''}',
                                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                        color: Colors.black87,
                                                      ),
                                                ),
                                                Text(
                                                  'التخصص: ${_linkedDoctor!['specialization'] ?? 'غير محدد'}',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Text(
                                            'لا يوجد دكتور معالج',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                  if (userProvider.accountType == 'doctor')
                                    Text(
                                      'التخصص: ${userProvider.specialization ?? 'غير محدد'}',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Colors.black87,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (userProvider.accountType == 'patient')
                            Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'السجل المرضي',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.teal.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'قياسات السكر',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    _parseGlucoseReadings().isEmpty
                                        ? Center(
                                            child: Text(
                                              'لا توجد قياسات متاحة',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          )
                                        : SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columns: const [
                                                DataColumn(
                                                  label: Text(
                                                    'الرقم',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'نوع القياس',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'مستوى السكر',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'التوقيت',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                                  ),
                                                ),
                                              ],
                                              rows: _parseGlucoseReadings()
                                                  .asMap()
                                                  .entries
                                                  .map(
                                                    (entry) {
                                                      final index = entry.key + 1;
                                                      final reading = entry.value;

                                                      final dateTime = DateTime.parse(reading['dateTime']);
                                                      final date =
                                                          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
                                                      final time = DateFormat('h:mm a')
                                                          .format(dateTime)
                                                          .replaceAll('AM', 'صباحاً')
                                                          .replaceAll('PM', 'مساءاً');

                                                      return DataRow(
                                                        cells: [
                                                          DataCell(Text(index.toString())),
                                                          DataCell(Text(reading['type'])),
                                                          DataCell(Text(reading['level'])),
                                                          DataCell(
                                                            Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(date),
                                                                Text(time),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  )
                                                  .toList(),
                                              columnSpacing: 20,
                                              dataRowMinHeight: 50,
                                              dataRowMaxHeight: 50,
                                              headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
                                            ),
                                          ),
                                    const SizedBox(height: 16),
                                    Divider(
                                      color: Colors.grey[300],
                                      thickness: 2.0,
                                      indent: 20,
                                      endIndent: 20,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'تحاليل السكر',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'اضغط على الصورة لعرضها بالكامل أو على أيقونة الحذف لحذف التحليل',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    _analysisImages.isEmpty
                                        ? Center(
                                            child: Text(
                                              'لا توجد تحاليل متاحة',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _analysisImages.length,
                                            itemBuilder: (context, index) {
                                              final imageData = _analysisImages[index];
                                              final int analysisId = imageData['id'] ?? 0;
                                              final String imageUrl = imageData['image'] ?? '';
                                              final String description = imageData['description'] ?? 'بدون وصف';
                                              final String comment = imageData['comment'] ?? 'لا يوجد توصية';
                                              final DateTime uploadDate =
                                                  DateTime.parse(imageData['uploaded_at'] ?? DateTime.now().toString());
                                              final String formattedDate = DateFormat('yyyy-MM-dd').format(uploadDate);

                                              debugPrint('Rendering analysis with ID: $analysisId, Description: $description');

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: Card(
                                                  elevation: 4,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: imageUrl.isEmpty
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
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(8),
                                                          child: Image.network(
                                                            'http://192.168.100.6:8000$imageUrl',
                                                            height: 150,
                                                            width: double.infinity,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) => Container(
                                                              height: 150,
                                                              color: Colors.grey.shade200,
                                                              child: const Center(
                                                                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                        child: IconButton(
                                                          icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                                                          tooltip: 'حذف التحليل',
                                                          onPressed: analysisId == 0
                                                              ? null
                                                              : () async {
                                                                  final bool? confirm = await _showDeleteConfirmationDialog(analysisId);
                                                                  if (confirm == true) {
                                                                    await _deleteAnalysis(analysisId);
                                                                  }
                                                                },
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                        child: Text(
                                                          'الوصف: $description',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                color: Colors.black87,
                                                                fontFamily: 'Cairo',
                                                              ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                        child: Text(
                                                          'تاريخ الرفع: $formattedDate',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                color: Colors.grey[600],
                                                                fontFamily: 'Cairo',
                                                              ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                        child: Text(
                                                          'توصية الدكتور: $comment',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                color: comment == 'لا يوجد توصية' ? Colors.grey[600] : Colors.black87,
                                                                fontFamily: 'Cairo',
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                );
                                if (result == true) {
                                  await _loadTokenAndFetchData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تعديل البيانات',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}