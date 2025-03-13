import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Youssef");
  final TextEditingController _emailController = TextEditingController(text: "youssef@gmail.com");
  final TextEditingController _passwordController = TextEditingController();
  bool _notificationsEnabled = true;

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الملف الشخصي والإعدادات')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _nameController, label: "الاسم الكامل", icon: Icons.person),
            SizedBox(height: 10),
            _buildTextField(controller: _emailController, label: "البريد الإلكتروني", icon: Icons.email, keyboardType: TextInputType.emailAddress),
            SizedBox(height: 10),
            _buildTextField(controller: _passwordController, label: "كلمة المرور الجديدة", icon: Icons.lock, obscureText: true),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text("تفعيل الإشعارات"),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              secondary: Icon(Icons.notifications),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, bool obscureText = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
