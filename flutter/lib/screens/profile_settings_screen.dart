import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _notificationsEnabled = true;

  Future<void> _logout() async {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _contactSupport() async {
    final whatsappNumber = "+201276619806";
    final whatsappUrl = Uri.parse("https://wa.me/$whatsappNumber");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تعذر فتح واتساب")),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
        enabled: enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الملف الشخصي والإعدادات')),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildTextField(controller: _nameController, label: "الاسم"),
              _buildTextField(controller: _emailController, label: "البريد الإلكتروني", enabled: false),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "التحكم في الإشعارات",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      SwitchListTile(
                        title: Text("تفعيل الإشعارات"),
                        value: _notificationsEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("تم حفظ التغييرات بنجاح!")),
                  );
                },
                child: Text("حفظ الإعدادات"),
              ),
              SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _logout,
                  child: Text(
                    "تسجيل الخروج",
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: Icon(Icons.support, color: Colors.white),
              label: Text("الدعم والشكاوى والاقتراحات"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}