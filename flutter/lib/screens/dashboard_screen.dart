import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'glucose_tracking_screen.dart';
import 'reminders_screen.dart';
import 'awareness_screen.dart';
import 'alternative_medications_screen.dart';
import 'ai_analysis_screen.dart';
import 'profile_screen.dart';
import 'patient_monitoring_screen.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/services/notification_service.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/user_provider.dart';
import 'dart:async';
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool _showWelcomeMessage = true;
  int _notificationCount = 0;
  int _patientCount = 0;
  bool _isLoadingPatientCount = false;
  String? _patientCountError;
  Timer? _notificationTimer;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    // تحميل البيانات عند بداية الشاشة
    Provider.of<UserProvider>(context, listen: false).loadUserData();
    _startNotificationPolling();
    _searchController.addListener(() {
      setState(() {});
    });
    // استدعاء جلب عدد المرضى
    fetchPatientCount();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPatientCount() async {
    debugPrint('Fetching patient count...');
    setState(() {
      _isLoadingPatientCount = true;
      _patientCountError = null;
    });
    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/my-patients/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        setState(() {
          _patientCountError = 'فشل الاتصال بالسيرفر';
        });
        debugPrint('Fetch Patient Count: Null response received');
        return;
      }

      debugPrint('Fetch Patient Count Response Status: ${response.statusCode}');
      debugPrint('Fetch Patient Count Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('Parsed Patient Count Data: $responseData');
        int patientCount = 0;
        if (responseData is List) {
          patientCount = responseData.length;
        } else if (responseData is Map && responseData.containsKey('patients')) {
          patientCount = (responseData['patients'] as List).length;
        } else if (responseData is Map && responseData.containsKey('data')) {
          patientCount = (responseData['data'] as List).length;
        } else {
          setState(() {
            _patientCountError = 'تنسيق استجابة غير متوقع';
          });
          debugPrint('Unexpected response format: $responseData');
          return;
        }
        setState(() {
          _patientCount = patientCount;
          debugPrint('Updated patient count: $_patientCount');
        });
      } else {
        setState(() {
          _patientCountError = 'فشل جلب البيانات: ${response.statusCode}';
        });
        debugPrint('Fetch Patient Count Failed: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _patientCountError = 'حدث خطأ: $e';
      });
      debugPrint('Fetch Patient Count Error: $e');
    } finally {
      setState(() {
        _isLoadingPatientCount = false;
      });
    }
  }

  Future<void> _updateNotificationCount() async {
    List<Map<String, dynamic>> notifications = await NotificationService.getLoggedNotifications();
    debugPrint('Fetched notifications: ${notifications.length}');
    if (!mounted) return;

    // تحديث عدد الإشعارات فقط
    setState(() {
      _notificationCount = notifications.length;
      debugPrint('Updated notification count: $_notificationCount');
    });
  }

  void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        await _updateNotificationCount();
      }
    });
  }

  void _showAllNotificationsDialog() async {
    List<Map<String, dynamic>> loggedNotifications = await NotificationService.getLoggedNotifications();
    debugPrint('Showing all notifications dialog with ${loggedNotifications.length} notifications');

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  'الإشعارات المرسلة',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: loggedNotifications.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد إشعارات حاليًا',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: loggedNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = loggedNotifications[index];
                            DateTime scheduledTime = DateTime.parse(notification['scheduled_time']);
                            final hour = scheduledTime.hour > 12
                                ? scheduledTime.hour - 12
                                : scheduledTime.hour == 0
                                    ? 12
                                    : scheduledTime.hour;
                            final minute = scheduledTime.minute.toString().padLeft(2, '0');
                            final period = scheduledTime.hour >= 12 ? 'مساءً' : 'صباحًا';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(0, 128, 128, 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Color.fromRGBO(0, 128, 128, 0.2)),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'],
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الوقت: $hour:$minute $period',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: loggedNotifications.isEmpty
                        ? null
                        : () async {
                            await NotificationService.clearLoggedNotifications();
                            setState(() {
                              loggedNotifications.clear();
                              if (mounted) {
                                _updateNotificationCount();
                              }
                            });
                          },
                    child: Text(
                      'مسح الكل',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: loggedNotifications.isEmpty ? Colors.grey : Colors.teal,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'إغلاق',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.teal,
                          ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ).then((_) {
        if (mounted) {
          _updateNotificationCount();
        }
      });
    }
  }

  Future<void> _logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      debugPrint('Access Token being sent: $accessToken');

      // إلغاء جميع الإشعارات ومسح سجل الإشعارات
      await NotificationService.cancelAllNotifications();
      await NotificationService.clearLoggedNotifications();

      // إرسال طلب تسجيل الخروج إلى الخادم إذا كان هناك رمز وصول
      if (accessToken != null) {
        final response = await HttpService().makeRequest(
          method: 'POST',
          url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/logout/'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response == null) {
          if (mounted) {
            _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
          }
        } else {
          debugPrint('Response Status: ${response.statusCode}');
          debugPrint('Response Body: ${response.body}');
        }
      }

      // مسح جميع بيانات SharedPreferences
      await prefs.clear();
      HttpService().clearTokens();

      if (mounted) {
        _showSnackBar('تم تسجيل الخروج بنجاح', Colors.green);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      HttpService().clearTokens();
      if (mounted) {
        _showSnackBar('حدث خطأ أثناء تسجيل الخروج: $e', Colors.red);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
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

  Future<List<Map<String, dynamic>>> _fetchDoctors(String query) async {
    final response = await HttpService().makeRequest(
      method: 'GET',
      url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/search-doctors/?query=$query'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response == null) {
      throw Exception('فشل الاتصال بالسيرفر');
    }

    debugPrint('Search API Response Status: ${response.statusCode}');
    debugPrint('Search API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint('Parsed Response Data: $responseData');

      if (responseData is List) {
        return List<Map<String, dynamic>>.from(responseData);
      } else if (responseData is Map) {
        var doctorsData = responseData['doctors'];
        if (doctorsData is List) {
          return List<Map<String, dynamic>>.from(doctorsData);
        } else if (doctorsData is Map) {
          return doctorsData.values.map((value) => Map<String, dynamic>.from(value)).toList();
        }
      }
    }
    return [];
  }

  Future<void> _searchDoctors(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final queryParts = query.trim().split(' ');

      if (queryParts.length >= 2) {
        final firstNameQuery = queryParts[0];
        final lastNameQuery = queryParts[1];

        final firstNameResults = await _fetchDoctors(firstNameQuery);
        final lastNameResults = await _fetchDoctors(lastNameQuery);

        _searchResults = [];

        final Map<String, Map<String, dynamic>> uniqueDoctors = {};

        for (var doctor in firstNameResults) {
          final firstName = (doctor['first_name'] ?? '').toString().toLowerCase();
          if (firstName.contains(firstNameQuery.toLowerCase())) {
            final doctorId = doctor['id'].toString();
            uniqueDoctors[doctorId] = doctor;
          }
        }

        for (var doctor in lastNameResults) {
          final lastName = (doctor['last_name'] ?? '').toString().toLowerCase();
          final doctorId = doctor['id'].toString();
          if (lastName.contains(lastNameQuery.toLowerCase()) && uniqueDoctors.containsKey(doctorId)) {
            _searchResults.add(uniqueDoctors[doctorId]!);
          }
        }

        if (_searchResults.isEmpty) {
          _searchError = 'لا توجد نتائج مطابقة';
        }
      } else {
        _searchResults = await _fetchDoctors(query);
        if (_searchResults.isEmpty) {
          _searchError = 'لا توجد نتائج مطابقة';
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() {
        _searchError = 'حدث خطأ: $e';
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget? screen, {
    bool isLogout = false,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Theme.of(context).primaryColor,
          size: 30,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isLogout ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        onTap: () async {
          if (isLogout) {
            _logout();
          } else {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => screen!),
            );
            if (title == 'الملف الشخصي' && result == true && mounted) {
              // تحديث البيانات بعد العودة من ProfileScreen
              Provider.of<UserProvider>(context, listen: false).loadUserData();
            }
          }
        },
      ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context, {
    required String title,
    required String imagePath,
    required Widget screen,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            debugPrint('Navigating to: $title');
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => screen),
            );
            if (title == 'الملف الشخصي' && result == true && mounted) {
              Provider.of<UserProvider>(context, listen: false).loadUserData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_showWelcomeMessage)
                Text(
                  'مرحبًا بك في تطبيق إدارة مرض السكر',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              if (userProvider.accountType == 'doctor')
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, color: Colors.teal, size: 30),
                        const SizedBox(width: 10),
                        _isLoadingPatientCount
                            ? const CircularProgressIndicator()
                            : _patientCountError != null
                                ? Text(
                                    _patientCountError!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.red,
                                        ),
                                  )
                                : Text(
                                    'عدد المرضى: $_patientCount',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                  ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'الصفحة الرئيسية',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              centerTitle: true,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.appBarGradient,
                ),
              ),
              actions: userProvider.accountType == 'patient'
                  ? [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications),
                            onPressed: _showAllNotificationsDialog,
                          ),
                          if (_notificationCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$_notificationCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ]
                  : null,
            ),
            drawer: Drawer(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.appBarGradient,
                      ),
                      child: SizedBox(
                        height: 350,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              userProvider.accountType == 'doctor'
                                  ? 'assets/images/doctor_logo.png.webp'
                                  : 'assets/images/patient_logo.png.webp',
                              height: 100,
                              width: 100,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${userProvider.firstName ?? 'الاسم'} ${userProvider.lastName ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              userProvider.email ?? 'الإيميل',
                              style: const TextStyle(
                                color: Color.fromARGB(179, 142, 6, 6),
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              userProvider.accountType == 'doctor' ? 'دكتور' : 'مريض',
                              style: const TextStyle(
                                color: Color.fromARGB(179, 194, 13, 13),
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDrawerItem(
                      context,
                      'الملف الشخصي',
                      Icons.person,
                      const ProfileScreen(),
                    ),
                    if (userProvider.accountType == 'patient') ...[
                      _buildDrawerItem(
                        context,
                        'تتبع مستوي السكر',
                        Icons.monitor_heart,
                        const GlucoseTrackingScreen(),
                      ),
                      _buildDrawerItem(
                        context,
                        'التذكيرات',
                        Icons.notifications,
                        const RemindersScreen(),
                      ),
                      _buildDrawerItem(
                        context,
                        'التنبؤ بمرض السكري',
                        Icons.analytics,
                        const AIAnalysisScreen(),
                      ),
                      _buildDrawerItem(
                        context,
                        'الأدوية البديلة',
                        Icons.medical_services,
                        const AlternativeMedicationsScreen(),
                      ),
                      _buildDrawerItem(
                        context,
                        'التوعية والإرشادات',
                        Icons.chat,
                        const AwarenessScreen(),
                      ),
                    ],
                    if (userProvider.accountType == 'doctor')
                      _buildDrawerItem(
                        context,
                        'متابعة المرضى',
                        Icons.people,
                        const PatientMonitoringScreen(),
                      ),
                    const Divider(),
                    const SizedBox(height: 10),
                    _buildDrawerItem(
                      context,
                      'تسجيل الخروج',
                      Icons.logout,
                      null,
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
              child: Column(
                children: [
                  _buildDashboardHeader(context),
                  if (userProvider.accountType == 'patient') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: _searchController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'البحث عن الطبيب',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          prefixIcon: const Icon(Icons.search, color: Colors.teal),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.teal),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _searchError = null;
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Color.fromRGBO(255, 255, 255, 0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onSubmitted: (value) {
                          _searchDoctors(value);
                        },
                      ),
                    ),
                    if (_isSearching)
                      const Center(child: CircularProgressIndicator()),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _searchError!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                      ),
                    if (_searchResults.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final doctor = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Colors.teal),
                                title: Text(
                                  '${doctor['first_name'] ?? 'غير متوفر'} ${doctor['last_name'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                subtitle: Text(
                                  doctor['specialization'] ?? 'غير محدد',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final response = await HttpService().makeRequest(
                                        method: 'POST',
                                        url: Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/link-to-doctor/'),
                                        headers: {'Content-Type': 'application/json'},
                                        body: jsonEncode({'doctor_id': doctor['id']}),
                                      );

                                      if (response == null) {
                                        _showSnackBar(
                                          'فشل الاتصال بالسيرفر',
                                          Colors.red,
                                        );
                                        return;
                                      }

                                      debugPrint('Link Doctor Response Status: ${response.statusCode}');
                                      debugPrint('Link Doctor Response Body: ${response.body}');

                                      if (response.statusCode == 201) {
                                        _showSnackBar(
                                          'تم طلب استشارة مع الدكتور ${doctor['first_name']} ${doctor['last_name']}',
                                          Colors.green,
                                        );
                                      } else {
                                        String errorMessage = 'خطأ غير معروف';
                                        if (response.headers['content-type']?.contains('application/json') == true) {
                                          try {
                                            final responseData = jsonDecode(response.body);
                                            errorMessage = responseData['error'] ?? 'خطأ غير معروف';
                                          } catch (e) {
                                            errorMessage = 'فشل تحليل الاستجابة: ${response.body}';
                                          }
                                        } else {
                                          errorMessage = 'استجابة غير متوقعة من السيرفر: ${response.body}';
                                        }
                                        _showSnackBar(
                                          'فشل طلب الاستشارة: $errorMessage',
                                          Colors.red,
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Link Doctor Error: $e');
                                      _showSnackBar(
                                        'حدث خطأ: $e',
                                        Colors.red,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: const Text(
                                    'طلب استشارة',
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                onTap: () {
                                  _showSnackBar(
                                    'تم تحديد الطبيب: ${doctor['first_name']}',
                                    Colors.green,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    if (!_isSearching && _searchResults.isEmpty && _searchError == null)
                      Expanded(
                        child: DashboardGrid(
                          buildDashboardButton: _buildDashboardButton,
                          accountType: userProvider.accountType,
                        ),
                      ),
                  ] else
                    Expanded(
                      child: DashboardGrid(
                        buildDashboardButton: _buildDashboardButton,
                        accountType: userProvider.accountType,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardGrid extends StatelessWidget {
  final Widget Function(
    BuildContext context, {
    required String title,
    required String imagePath,
    required Widget screen,
  }) buildDashboardButton;
  final String? accountType;

  const DashboardGrid({
    super.key,
    required this.buildDashboardButton,
    required this.accountType,
  });

  List<Map<String, dynamic>> get _dashboardItems {
    List<Map<String, dynamic>> items = [
      {
        'title': 'الملف الشخصي',
        'imagePath': 'assets/images/profile.png.webp',
        'screen': const ProfileScreen(),
      },
    ];

    if (accountType == 'patient') {
      items.insertAll(0, [
        {
          'title': 'تتبع مستوي السكر',
          'imagePath': 'assets/images/glucose_tracking.png.webp',
          'screen': const GlucoseTrackingScreen(),
        },
        {
          'title': 'التذكيرات',
          'imagePath': 'assets/images/reminders.png.webp',
          'screen': const RemindersScreen(),
        },
        {
          'title': 'التنبؤ بمرض السكر',
          'imagePath': 'assets/images/ai_analysis.png.webp',
          'screen': const AIAnalysisScreen(),
        },
        {
          'title': 'الأدوية البديلة',
          'imagePath': 'assets/images/medications.png.webp',
          'screen': const AlternativeMedicationsScreen(),
        },
        {
          'title': 'التوعية والإرشادات',
          'imagePath': 'assets/images/help.png.webp',
          'screen': const AwarenessScreen(),
        },
      ]);
    } else if (accountType == 'doctor') {
      items.insert(0, {
        'title': 'متابعة المرضى',
        'imagePath': 'assets/images/patient_monitoring.png.webp',
        'screen': const PatientMonitoringScreen(),
      });
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _dashboardItems.length,
      itemBuilder: (context, index) {
        final item = _dashboardItems[index];
        return buildDashboardButton(
          context,
          title: item['title'],
          imagePath: item['imagePath'],
          screen: item['screen'],
        );
      },
    );
  }
}