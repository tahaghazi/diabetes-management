import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'glucose_tracking_screen.dart';
import 'reminders_screen.dart';
import 'chatbot_screen.dart';
import 'alternative_medications_screen.dart';
import 'ai_analysis_screen.dart';
import 'profile_screen.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool _showWelcomeMessage = true;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;
  int _notificationCount = 0;
  Timer? _notificationTimer;
  List<Map<String, dynamic>> _lastNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startNotificationPolling();
    Future.delayed(Duration(seconds: 5), () {
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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name');
      _lastName = prefs.getString('last_name');
      _email = prefs.getString('user_email');
      _accountType = prefs.getString('account_type');
      _specialization = prefs.getString('specialization');
      debugPrint('Loaded first_name: $_firstName');
      debugPrint('Loaded last_name: $_lastName');
      debugPrint('Loaded email: $_email');
      debugPrint('Loaded account_type: $_accountType');
      debugPrint('Loaded specialization: $_specialization');
    });

    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');
    if (accessToken != null && refreshToken != null) {
      HttpService().setTokens(accessToken, refreshToken);
      debugPrint('Tokens updated in HttpService: Access Token: $accessToken, Refresh Token: $refreshToken');
    }
  }

  Future<void> _updateNotificationCount() async {
    List<Map<String, dynamic>> notifications = await NotificationService.getLoggedNotifications();
    debugPrint('Fetched notifications: ${notifications.length}');
    if (!mounted) return;
    setState(() {
      _notificationCount = notifications.length;
      debugPrint('Updated notification count: $_notificationCount');
    });

    if (notifications.length > _lastNotifications.length) {
      var newNotifications = notifications
          .where((n) => !_lastNotifications.any((ln) => ln['id'] == n['id'] && ln['scheduled_time'] == n['scheduled_time']))
          .toList();
      debugPrint('New notifications: ${newNotifications.length}');
      _lastNotifications = List.from(notifications);
      if (newNotifications.isNotEmpty && mounted) {
        debugPrint('Showing dialog for new notification: ${newNotifications.last}');
        _showNewNotificationDialog(newNotifications.last);
      }
    }
  }

  void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (mounted) {
        await _updateNotificationCount();
      }
    });
  }

  void _showNewNotificationDialog(Map<String, dynamic> notification) {
    DateTime scheduledTime = DateTime.parse(notification['scheduled_time']);
    final hour = scheduledTime.hour > 12
        ? scheduledTime.hour - 12
        : scheduledTime.hour == 0
            ? 12
            : scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = scheduledTime.hour >= 12 ? 'مساءً' : 'صباحًا';

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              notification['title'],
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'الوقت: $hour:$minute $period',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إغلاق', style: TextStyle(color: Colors.teal)),
              ),
            ],
          );
        },
      ).then((_) {
        if (mounted) {
          _updateNotificationCount();
        }
      });
    }
  }

  void _showAllNotificationsDialog() async {
    List<Map<String, dynamic>> loggedNotifications =
        await NotificationService.getLoggedNotifications();
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
                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: loggedNotifications.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد إشعارات حاليًا',
                            style: TextStyle(color: Colors.grey),
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
                                  color: Colors.teal.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                                ),
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'],
                                      style: TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'الوقت: $hour:$minute $period',
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
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
                    child: Text('مسح الكل', style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إغلاق', style: TextStyle(color: Colors.teal)),
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

      if (accessToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تم تسجيل الخروج')));
        await prefs.clear();
        HttpService().clearTokens();
        if (!mounted) return;
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
        return;
      }

      final response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://10.0.2.2:8000/api/logout/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        if (!mounted) return;
        await prefs.clear();
        HttpService().clearTokens();
        if (!mounted) return;
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
        return;
      }

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      await prefs.clear();
      HttpService().clearTokens();

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تم تسجيل الخروج بنجاح')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تسجيل الخروج: ${response.statusCode} - ${response.body}')));
      }

      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (e) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج: $e')));
      await prefs.clear();
      HttpService().clearTokens();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, Widget? screen,
      {bool isLogout = false}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue, size: 30),
        title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black, fontSize: 18)),
        onTap: () async {
          if (isLogout) {
            _logout();
          } else {
            final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen!));
            if (title == 'الملف الشخصي' && result == true && mounted) {
              await _loadUserData();
            }
          }
        },
      ),
    );
  }

  Widget _buildDashboardButton(BuildContext context,
      {required String title, required String imagePath, required Widget screen}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () async {
          debugPrint('Navigating to: $title');
          final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
          if (title == 'الملف الشخصي' && result == true && mounted) {
            await _loadUserData();
          }
        },
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              debugPrint('Navigating to: $title');
              final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
              if (title == 'الملف الشخصي' && result == true && mounted) {
                await _loadUserData();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity)),
                  SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الصفحة الرئيسية',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.teal, Colors.tealAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: Colors.white),
                  onPressed: _showAllNotificationsDialog,
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration:
                          BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_notificationCount',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5))
                        ],
                      ),
                      child: Image.asset(
                        _accountType == 'doctor'
                            ? 'assets/images/doctor_logo.png.webp'
                            : 'assets/images/patient_logo.png.webp',
                        height: 80,
                        width: 80,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '${_firstName ?? 'الاسم'} ${_lastName ?? ''}',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(_email ?? 'الإيميل',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                        textAlign: TextAlign.center),
                    SizedBox(height: 12),
                    Text(_accountType == 'doctor' ? 'دكتور' : 'مريض',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              _buildDrawerItem(context, 'تتبع تحليل السكر', Icons.monitor_heart, GlucoseTrackingScreen()),
              _buildDrawerItem(context, 'التذكيرات', Icons.notifications, RemindersScreen()),
              _buildDrawerItem(context, 'التنبؤ بمرض السكر', Icons.analytics, AIAnalysisScreen()),
              _buildDrawerItem(
                  context, 'الأدوية البديلة', Icons.medical_services, AlternativeMedicationsScreen()),
              _buildDrawerItem(context, 'الشات بوت', Icons.chat, ChatbotScreen()),
              _buildDrawerItem(context, 'الملف الشخصي', Icons.person, ProfileScreen()),
              Divider(),
              Spacer(),
              _buildDrawerItem(context, 'تسجيل الخروج', Icons.logout, null, isLogout: true),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.teal[50]!, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
          ),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (_showWelcomeMessage)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'مرحبًا بك في تطبيق إدارة مرض السكري',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(child: DashboardGrid(buildDashboardButton: _buildDashboardButton)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardGrid extends StatelessWidget {
  final Widget Function(BuildContext context,
      {required String title, required String imagePath, required Widget screen}) buildDashboardButton;

  const DashboardGrid({super.key, required this.buildDashboardButton});

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

final List<Map<String, dynamic>> _dashboardItems = [
  {
    'title': 'تتبع تحليل السكر',
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
    'title': 'الشات بوت',
    'imagePath': 'assets/images/chatbot.png.webp',
    'screen': const ChatbotScreen(),
  },
  {
    'title': 'الملف الشخصي',
    'imagePath': 'assets/images/profile.png.webp',
    'screen': const ProfileScreen(),
  },
];