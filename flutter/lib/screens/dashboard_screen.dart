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
import 'package:diabetes_management/config/theme.dart';

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
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name') ?? 'غير متوفر';
      _lastName = prefs.getString('last_name') ?? '';
      _email = prefs.getString('user_email') ?? 'غير متوفر';
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
    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
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

    IconData notificationIcon;
    Color notificationColor;
    switch (notification['reminder_type'].toLowerCase()) {
      case 'blood_glucose_test':
        notificationIcon = Icons.monitor_heart;
        notificationColor = Colors.teal;
        break;
      case 'hydration':
        notificationIcon = Icons.water_drop;
        notificationColor = Colors.tealAccent;
        break;
      case 'medication':
        notificationIcon = Icons.medical_services;
        notificationColor = Colors.teal;
        break;
      default:
        notificationIcon = Icons.notifications_active;
        notificationColor = Theme.of(context).primaryColor;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  notificationIcon,
                  size: 40,
                  color: notificationColor,
                ),
                const SizedBox(height: 16),
                Text(
                  notification['title'],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: notificationColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'الوقت: $hour:$minute $period',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (notification['reminder_type'].toLowerCase() == 'medication' &&
                    notification['medication_name'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'الدواء: ${notification['medication_name']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'إغلاق',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
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
                                  color: Colors.teal.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
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

      if (accessToken == null) {
        if (!mounted) return;
        _showSnackBar('تم تسجيل الخروج', Colors.green);
        await prefs.clear();
        HttpService().clearTokens();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      await prefs.clear();
      HttpService().clearTokens();

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        _showSnackBar('تم تسجيل الخروج بنجاح', Colors.green);
      } else {
        if (!mounted) return;
        _showSnackBar('فشل تسجيل الخروج: ${response.statusCode} - ${response.body}', Colors.red);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _showSnackBar('حدث خطأ أثناء تسجيل الخروج: $e', Colors.red);
      await prefs.clear();
      HttpService().clearTokens();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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
              await _loadUserData();
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
              await _loadUserData();
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

  @override
  Widget build(BuildContext context) {
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
          actions: [
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
          ],
        ),
        drawer: Drawer(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.appBarGradient,
                  ),
                  child: SizedBox(
                    height: 400,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          _accountType == 'doctor'
                              ? 'assets/images/doctor_logo.png.webp'
                              : 'assets/images/patient_logo.png.webp',
                          height: 60,
                          width: 60,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_firstName ?? 'الاسم'} ${_lastName ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _email ?? 'الإيميل',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _accountType == 'doctor' ? 'دكتور' : 'مريض',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  'الملف الشخصي',
                  Icons.person,
                  const ProfileScreen(),
                ),
                _buildDrawerItem(
                  context,
                  'تتبع تحليل السكر',
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
                  'التنبؤ بمرض السكر',
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
                  'الشات بوت',
                  Icons.chat,
                  const ChatbotScreen(),
                ),
                const Divider(),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (_showWelcomeMessage)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'مرحبًا بك في تطبيق إدارة مرض السكري',
                      style: Theme.of(context).textTheme.headlineMedium,
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
  final Widget Function(
    BuildContext context, {
    required String title,
    required String imagePath,
    required Widget screen,
  }) buildDashboardButton;

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