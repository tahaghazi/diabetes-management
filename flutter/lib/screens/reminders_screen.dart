import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/services/notification_service.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:logger/logger.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  RemindersScreenState createState() => RemindersScreenState();
}

class RemindersScreenState extends State<RemindersScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReminderType;
  TimeOfDay? _selectedTime;
  String? _medicationName;
  final TextEditingController _medicationController = TextEditingController();
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = false;
  final Logger _logger = Logger();

  final List<String> _reminderTypes = [
    'تحليل السكر',
    'الدواء',
    'شرب الماء',
  ];

  final Map<String, String> _reminderTypeToApiValue = {
    'تحليل السكر': 'blood_glucose_test',
    'الدواء': 'medication',
    'شرب الماء': 'hydration',
  };

  final Map<String, String> _apiValueToReminderType = {
    'blood_glucose_test': 'تحليل السكر',
    'medication': 'الدواء',
    'hydration': 'شرب الماء',
  };

  final Map<String, List<Color>> _reminderTypeColors = {
    'تحليل السكر': [Colors.purple.shade400, Colors.purple.shade200],
    'الدواء': [Colors.orange.shade400, Colors.orange.shade200],
    'شرب الماء': [Colors.blue.shade400, Colors.blue.shade200],
  };

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? refreshToken = prefs.getString('refresh_token');
      if (accessToken != null && refreshToken != null) {
        HttpService().setTokens(accessToken, refreshToken);
      }

      if (accessToken == null) {
        if (!mounted) return;
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/get-reminders/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response == null) {
        if (!mounted) return;
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 200) {
        var responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        setState(() {
          _reminders = List<Map<String, dynamic>>.from(responseData).map((reminder) {
            return {
              ...reminder,
              'reminder_type': _apiValueToReminderType[reminder['reminder_type']] ?? reminder['reminder_type'],
            };
          }).toList();
        });

        for (var reminder in _reminders) {
          if (reminder['active']) {
            _scheduleNotificationForReminder(reminder);
          }
        }
      } else {
        if (!mounted) return;
        _showSnackBar('فشل تحميل التذكيرات', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _addReminder() async {
    if (!_formKey.currentState!.validate() || _selectedTime == null) {
      if (!mounted) return;
      _showSnackBar('يرجى اختيار نوع التذكير والوقت', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        if (!mounted) return;
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var requestBody = {
        'reminder_type': _reminderTypeToApiValue[_selectedReminderType]!,
        'reminder_time': '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
        'active': true,
        if (_medicationName != null && _selectedReminderType == 'الدواء') 'medication_name': _medicationName,
      };

      _logger.d('Request Body: $requestBody');

      var tempReminder = {
        'reminder_type': _selectedReminderType,
        'reminder_time': requestBody['reminder_time'],
        'active': true,
        if (_medicationName != null && _selectedReminderType == 'الدواء') 'medication_name': _medicationName,
        'id': -1,
      };

      setState(() {
        _reminders.add(tempReminder);
      });

      var response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://192.168.100.6:8000/api/create-reminder/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(requestBody),
      );

      if (response == null) {
        setState(() {
          _reminders.remove(tempReminder);
        });
        if (!mounted) return;
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 201) {
        var newReminder = jsonDecode(utf8.decode(response.bodyBytes));
        _logger.d('Response Data: $newReminder');
        if (!mounted) return;
        _showSnackBar('تم إضافة التذكير بنجاح!', Colors.green);
        setState(() {
          _reminders.remove(tempReminder);
          _reminders.add({
            ...newReminder,
            'reminder_type': _apiValueToReminderType[newReminder['reminder_type']] ?? newReminder['reminder_type'],
          });
        });
        _scheduleNotificationForReminder(newReminder);
        _selectedReminderType = null;
        _selectedTime = null;
        _medicationName = null;
        _medicationController.clear();
      } else {
        setState(() {
          _reminders.remove(tempReminder);
        });
        var responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        _showSnackBar(responseData['error'] ?? 'حدث خطأ أثناء إضافة التذكير', Colors.red);
      }
    } catch (e) {
      setState(() {
        _reminders.removeWhere((r) => r['id'] == -1);
      });
      if (!mounted) return;
      _showSnackBar('فشل الاتصال بالسيرفر: $e', Colors.red);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _updateReminder(int id, String reminderType, TimeOfDay newTime, String? medicationName) async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        if (!mounted) return;
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var requestBody = {
        'reminder_type': _reminderTypeToApiValue[reminderType]!,
        'reminder_time': '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}:00',
        if (reminderType == 'الدواء') 'medication_name': medicationName,
      };

      var response = await HttpService().makeRequest(
        method: 'PUT',
        url: Uri.parse('http://192.168.100.6:8000/api/update-reminder/$id/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(requestBody),
      );

      if (response == null) {
        if (!mounted) return;
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 200) {
        var updatedReminder = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        _showSnackBar('تم تعديل التذكير بنجاح!', Colors.green);
        await NotificationService.cancelNotification(id);
        _scheduleNotificationForReminder(updatedReminder);
        await _loadReminders();
      } else {
        var responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        _showSnackBar(responseData['error'] ?? 'حدث خطأ أثناء تعديل التذكير', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل الاتصال بالسيرفر: $e', Colors.red);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _deleteReminder(int id, int index) async {
    setState(() => _isLoading = true);
    var tempReminder = _reminders[index];
    setState(() {
      _reminders.removeAt(index);
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        setState(() {
          _reminders.insert(index, tempReminder);
        });
        if (!mounted) return;
        _showSnackBar('يرجى تسجيل الدخول مرة أخرى', Colors.red);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      var response = await HttpService().makeRequest(
        method: 'DELETE',
        url: Uri.parse('http://192.168.100.6:8000/api/delete-reminder/$id/'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response == null) {
        setState(() {
          _reminders.insert(index, tempReminder);
        });
        if (!mounted) return;
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 204) {
        if (!mounted) return;
        _showSnackBar('تم حذف التذكير بنجاح!', Colors.green);
        await NotificationService.cancelNotification(id);
      } else {
        setState(() {
          _reminders.insert(index, tempReminder);
        });
        if (!mounted) return;
        _showSnackBar('فشل حذف التذكير', Colors.red);
      }
    } catch (e) {
      setState(() {
        _reminders.insert(index, tempReminder);
      });
      if (!mounted) return;
      _showSnackBar('فشل الاتصال بالسيرفر: $e', Colors.red);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _scheduleNotificationForReminder(Map<String, dynamic> reminder) {
    final timeParts = reminder['reminder_time'].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    final reminderType = _apiValueToReminderType[reminder['reminder_type']] ?? reminder['reminder_type'];

    _logger.d('Notification Title: تذكير: $reminderType');
    _logger.d('Notification Body: ${reminderType == 'الدواء' && reminder['medication_name'] != null ? 'حان وقت $reminderType (${reminder['medication_name']})!' : 'حان وقت $reminderType!'}');

    NotificationService.scheduleDailyNotification(
      id: reminder['id'],
      title: 'تذكير: $reminderType',
      body: reminderType == 'الدواء' && reminder['medication_name'] != null
          ? 'حان وقت $reminderType (${reminder['medication_name']})!'
          : 'حان وقت $reminderType!',
      scheduledTime: scheduledTime,
      reminderType: _reminderTypeToApiValue[reminderType] ?? reminder['reminder_type'],
      medicationName: reminder['medication_name'],
    );
  }

  void _selectTime(BuildContext context, {TimeOfDay? initialTime, required Function(TimeOfDay) onTimeSelected}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'مساءً' : 'صباحًا';
    return '$hour:$minute $period';
  }

  void _showEditDialog(Map<String, dynamic> reminder) {
    String? editReminderType = _apiValueToReminderType[reminder['reminder_type']] ?? reminder['reminder_type'];
    TimeOfDay? editTime;
    String? editMedicationName = reminder['medication_name'];
    final timeParts = reminder['reminder_time'].split(':');
    editTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    final TextEditingController medicationController = TextEditingController(text: editMedicationName);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تعديل التذكير',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (editReminderType != null && editTime != null) {
                _updateReminder(reminder['id'], editReminderType!, editTime!, editMedicationName);
                Navigator.pop(context);
              } else {
                _showSnackBar('يرجى ملء جميع الحقول', Colors.red);
              }
            },
            child: Text(
              'حفظ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ),
        ],
        content: StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: editReminderType,
                      decoration: InputDecoration(
                        labelText: 'نوع التذكير',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        prefixIcon: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      items: _reminderTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          editReminderType = newValue;
                          if (newValue != 'الدواء') {
                            editMedicationName = null;
                            medicationController.clear();
                          }
                        });
                      },
                      validator: (value) => value == null ? 'يرجى اختيار نوع التذكير' : null,
                    ),
                    const SizedBox(height: 16),
                    if (editReminderType == 'الدواء')
                      TextFormField(
                        controller: medicationController,
                        decoration: InputDecoration(
                          labelText: 'اسم الدواء (اختياري)',
                          labelStyle: Theme.of(context).textTheme.bodyMedium,
                          prefixIcon: Icon(Icons.medical_services, color: Theme.of(context).primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                        onChanged: (value) {
                          editMedicationName = value.isEmpty ? null : value;
                          _logger.d('Medication Name Input: $editMedicationName');
                        },
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _selectTime(
                        context,
                        initialTime: editTime,
                        onTimeSelected: (picked) {
                          setState(() {
                            editTime = picked;
                          });
                        },
                      ),
                      child: Text(
                        editTime == null ? 'اختر الوقت' : 'الوقت: ${_formatTime(editTime!)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(anim1),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _showAddReminderDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        title: Text(
          'إضافة تذكير جديد',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && _selectedTime != null) {
                _addReminder();
                Navigator.pop(context);
              } else {
                _showSnackBar('يرجى ملء جميع الحقول', Colors.red);
              }
            },
            child: Text(
              'إضافة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ),
        ],
        content: StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedReminderType,
                        decoration: InputDecoration(
                          labelText: 'نوع التذكير',
                          labelStyle: Theme.of(context).textTheme.bodyMedium,
                          prefixIcon: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                        items: _reminderTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedReminderType = newValue;
                            _medicationName = null;
                            _medicationController.clear();
                          });
                        },
                        validator: (value) => value == null ? 'يرجى اختيار نوع التذكير' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedReminderType == 'الدواء')
                        TextFormField(
                          controller: _medicationController,
                          decoration: InputDecoration(
                            labelText: 'اسم الدواء (اختياري)',
                            labelStyle: Theme.of(context).textTheme.bodyMedium,
                            prefixIcon: Icon(Icons.medical_services, color: Theme.of(context).primaryColor),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          onChanged: (value) {
                            setState(() {
                              _medicationName = value.isEmpty ? null : value;
                              _logger.d('Medication Name Input: $_medicationName');
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _selectTime(
                          context,
                          onTimeSelected: (picked) {
                            setState(() {
                              _selectedTime = picked;
                            });
                          },
                        ),
                        child: Text(
                          _selectedTime == null
                              ? 'اختر الوقت'
                              : 'التذكير: ${_formatTime(_selectedTime!)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(anim1),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder, int index) {
    final timeParts = reminder['reminder_time'].split(':');
    final time = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

    IconData iconData;
    switch (reminder['reminder_type']) {
      case 'تحليل السكر':
        iconData = Icons.bloodtype;
        break;
      case 'الدواء':
        iconData = Icons.medical_services;
        break;
      case 'شرب الماء':
        iconData = Icons.local_drink;
        break;
      default:
        iconData = Icons.notifications;
    }

    final gradientColors = _reminderTypeColors[reminder['reminder_type']] ??
        [Colors.grey.shade400, Colors.grey.shade200];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(iconData, color: gradientColors[0]),
          ),
          title: Text(
            reminder['reminder_type'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          subtitle: Text(
            reminder['reminder_type'] == 'الدواء' && reminder['medication_name'] != null
                ? '${_formatTime(time)} - ${reminder['medication_name']}'
                : _formatTime(time),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _showEditDialog(reminder),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _deleteReminder(reminder['id'], index),
              ),
            ],
          ),
          onTap: () => _showEditDialog(reminder),
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupRemindersByType() {
    Map<String, List<Map<String, dynamic>>> groupedReminders = {
      'تحليل السكر': [],
      'الدواء': [],
      'شرب الماء': [],
    };

    for (var reminder in _reminders) {
      groupedReminders[reminder['reminder_type']]?.add(reminder);
    }

    return groupedReminders;
  }

  @override
  Widget build(BuildContext context) {
    final groupedReminders = _groupRemindersByType();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التذكيرات',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.appBarGradient,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
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
              : _reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 80,
                            color: Color.fromRGBO(0, 128, 128, 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد تذكيرات حاليًا',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Color.fromRGBO(0, 128, 128, 0.7),
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: groupedReminders.entries.map((entry) {
                        final reminderType = entry.key;
                        final reminders = entry.value;

                        if (reminders.isEmpty) return const SizedBox.shrink();

                        return ExpansionTile(
                          leading: Icon(
                            reminderType == 'تحليل السكر'
                                ? Icons.bloodtype
                                : reminderType == 'الدواء'
                                    ? Icons.medical_services
                                    : Icons.local_drink,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            reminderType,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          initiallyExpanded: true,
                          children: reminders.asMap().entries.map((entry) {
                            final index = entry.key;
                            final reminder = entry.value;
                            return _buildReminderItem(reminder, index);
                          }).toList(),
                        );
                      }).toList(),
                    ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddReminderDialog,
          tooltip: 'إضافة تذكير',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}