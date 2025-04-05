import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'glucose_tracking_screen.dart';
import 'reminders_screen.dart';
import 'chatbot_screen.dart';
import 'alternative_medications_screen.dart';
import 'ai_analysis_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showWelcomeMessage = true;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name');
      _lastName = prefs.getString('last_name');
      _email = prefs.getString('user_email');
      _accountType = prefs.getString('account_type');
      _specialization = prefs.getString('specialization');
    });
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, Widget? screen, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.blue, size: 30),
      title: Text(title, style: TextStyle(color: isLogout ? Colors.red : Colors.black, fontSize: 18)),
      onTap: () {
        if (isLogout) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
        }
      },
    );
  }

  Widget _buildDashboardButton(BuildContext context, {required String title, required String imagePath, required Widget screen}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الصفحة الرئيسية',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      _accountType == 'doctor' ? 'assets/images/doctor_logo.png.webp' : 'assets/images/patient_logo.png.webp',
                      height: 80,
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_firstName ?? 'الاسم'} ${_lastName ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _email ?? 'الإيميل',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _accountType == 'doctor' ? 'دكتور' : 'مريض',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  if (_accountType == 'doctor')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'التخصص: ${_specialization ?? 'غير محدد'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            _buildDrawerItem(context, 'تتبع مستوى السكر', Icons.monitor_heart, GlucoseTrackingScreen()),
            _buildDrawerItem(context, 'التذكيرات', Icons.notifications, RemindersScreen()),
            _buildDrawerItem(context, 'الشات بوت', Icons.chat, ChatbotScreen()),
            _buildDrawerItem(context, 'الأدوية البديلة', Icons.medical_services, AlternativeMedicationsScreen()),
            _buildDrawerItem(context, 'التنبؤ بمرض السكر', Icons.analytics, AIAnalysisScreen()),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red, size: 30),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontSize: 18)),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_showWelcomeMessage)
              const Padding(
                padding: EdgeInsets.only(bottom: 20), // يجب تصحيحه إلى bottom: 20
                child: Text(
                  'مرحبًا بك في تطبيق إدارة مرض السكري',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            Expanded(
              child: DashboardGrid(
                buildDashboardButton: _buildDashboardButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardGrid extends StatelessWidget {
  final Widget Function(BuildContext, {required String title, required String imagePath, required Widget screen}) buildDashboardButton;

  const DashboardGrid({Key? key, required this.buildDashboardButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
    'title': 'تتبع مستوى السكر',
    'imagePath': 'assets/images/glucose_tracking.png.webp',
    'screen': GlucoseTrackingScreen(),
  },
  {
    'title': 'التذكيرات',
    'imagePath': 'assets/images/reminders.png.webp',
    'screen': RemindersScreen(),
  },
  {
    'title': 'الشات بوت',
    'imagePath': 'assets/images/chatbot.png.webp',
    'screen': ChatbotScreen(),
  },
  {
    'title': 'الأدوية البديلة',
    'imagePath': 'assets/images/medications.png.webp',
    'screen': AlternativeMedicationsScreen(),
  },
  {
    'title': 'التنبؤ بمرض السكر',
    'imagePath': 'assets/images/ai_analysis.png.webp',
    'screen': AIAnalysisScreen(),
  },
];