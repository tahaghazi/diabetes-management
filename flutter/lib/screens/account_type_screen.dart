import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart'; // استيراد الثيم

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  AccountTypeScreenState createState() => AccountTypeScreenState();
}

class AccountTypeScreenState extends State<AccountTypeScreen> {
  String? _selectedAccountType;

  void _navigateToSignUp() {
    if (_selectedAccountType == null) {
      _showSnackBar('يرجى اختيار نوع الحساب', Colors.red);
      return;
    }

    Navigator.pushNamed(
      context,
      '/sign_up',
      arguments: _selectedAccountType!,
    );
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'اختر نوع الحساب',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient, // استخدام تدرج AppBar من الثيم
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient, // استخدام تدرج الخلفية من الثيم
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختر نوع الحساب الخاص بك',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 30),
                _buildAccountTypeOption('مريض', 'patient', 'assets/images/patient_logo.png.webp'),
                const SizedBox(height: 20),
                _buildAccountTypeOption('دكتور', 'doctor', 'assets/images/doctor_logo.png.webp'),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _navigateToSignUp,
                  child: Text(
                    'التالي',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  Widget _buildAccountTypeOption(String title, String value, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _selectedAccountType == value ? Colors.teal.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: _selectedAccountType == value ? Colors.teal : Colors.teal.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _selectedAccountType == value ? Colors.teal : Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}