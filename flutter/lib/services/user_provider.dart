import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // أضف هذا السطر

class UserProvider with ChangeNotifier {
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _accountType;
  String? _specialization;

  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get accountType => _accountType;
  String? get specialization => _specialization;

  void updateUser({
    String? firstName,
    String? lastName,
    String? email,
    String? accountType,
    String? specialization,
  }) {
    _firstName = firstName;
    _lastName = lastName;
    _email = email;
    _accountType = accountType;
    _specialization = specialization;
    notifyListeners(); // إخطار الواجهة بالتحديث
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _firstName = prefs.getString('first_name') ?? 'غير متوفر';
    _lastName = prefs.getString('last_name') ?? '';
    _email = prefs.getString('user_email') ?? 'غير متوفر';
    _accountType = prefs.getString('account_type');
    _specialization = prefs.getString('specialization');
    notifyListeners();
  }
}