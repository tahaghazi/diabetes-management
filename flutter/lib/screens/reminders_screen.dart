import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/services/notification_service.dart';

// ignore: library_private_types_in_public_api
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReminderType;
  TimeOfDay? _selectedTime;
  String? _medicationName;
  final TextEditingController _medicationController = TextEditingController();
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _loadReminders();
    _setupDefaultReminders();
  }

  Future<void> _setupDefaultReminders() async {
    await _addDefaultReminder('تحليل السكر', TimeOfDay(hour: 8, minute: 0));
    for (int hour = 8; hour <= 22; hour += 2) {
      await _addDefaultReminder('شرب الماء', TimeOfDay(hour: hour, minute: 0));
    }
  }

  Future<void> _addDefaultReminder(String type, TimeOfDay time) async {
    var existingReminders = _reminders.where((r) =>
        r['reminder_type'] == type &&
        r['reminder_time'] == '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00');
    if (existingReminders.isEmpty) {
      await _addReminder(type: type, time: time, isDefault: true);
    }
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
        url: Uri.parse('http://10.0.2.2:8000/api/get-reminders/'),
        headers: {'Content-Type': 'application/json'},
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

  Future<void> _addReminder({String? type, TimeOfDay? time, bool isDefault = false}) async {
    if (!isDefault && !_formKey.currentState!.validate()) return;
    if ((time ?? _selectedTime) == null) {
      if (!mounted) return;
      _showSnackBar('يرجى اختيار وقت التذكير', Colors.red);
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
        'reminder_type': _reminderTypeToApiValue[type ?? _selectedReminderType]!,
        'reminder_time': '${(time ?? _selectedTime!).hour.toString().padLeft(2, '0')}:${(time ?? _selectedTime!).minute.toString().padLeft(2, '0')}:00',
        'active': true,
        if (_medicationName != null && (type ?? _selectedReminderType) == 'الدواء') 'medication_name': _medicationName,
      };

      var response = await HttpService().makeRequest(
        method: 'POST',
        url: Uri.parse('http://10.0.2.2:8000/api/create-reminder/'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response == null) {
        if (!mounted) return;
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 201) {
        var newReminder = jsonDecode(response.body);
        if (!mounted) return;
        _showSnackBar('تم إضافة التذكير بنجاح!', Colors.green);
        if (!isDefault) {
          _selectedReminderType = null;
          _selectedTime = null;
          _medicationName = null;
          _medicationController.clear();
        }
        _scheduleNotificationForReminder(newReminder);
        await _loadReminders();
      } else {
        var responseData = jsonDecode(response.body);
        if (!mounted) return;
        _showSnackBar(responseData['error'] ?? 'حدث خطأ أثناء إضافة التذكير', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _updateReminder(int id, String reminderType, TimeOfDay newTime) async {
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
      };

      var response = await HttpService().makeRequest(
        method: 'PUT',
        url: Uri.parse('http://10.0.2.2:8000/api/update-reminder/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response == null) {
        if (!mounted) return;
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 200) {
        var updatedReminder = jsonDecode(response.body);
        if (!mounted) return;
        _showSnackBar('تم تعديل التذكير بنجاح!', Colors.green);
        await NotificationService.cancelNotification(id);
        _scheduleNotificationForReminder(updatedReminder);
        _loadReminders();
      } else {
        var responseData = jsonDecode(response.body);
        if (!mounted) return;
        _showSnackBar(responseData['error'] ?? 'حدث خطأ أثناء تعديل التذكير', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _deleteReminder(int id, int index) async {
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

      var response = await HttpService().makeRequest(
        method: 'DELETE',
        url: Uri.parse('http://10.0.2.2:8000/api/delete-reminder/$id/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response == null) {
        if (!mounted) return;
        _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
        return;
      }

      if (response.statusCode == 204) {
        if (!mounted) return;
        _showSnackBar('تم حذف التذكير بنجاح!', Colors.green);
        await NotificationService.cancelNotification(id);
        setState(() {
          _reminders.removeAt(index);
        });
      } else {
        if (!mounted) return;
        _showSnackBar('فشل حذف التذكير', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل الاتصال بالسيرفر', Colors.red);
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

    NotificationService.scheduleDailyNotification(
      id: reminder['id'],
      title: 'تذكير: ${reminder['reminder_type']}',
      body: reminder['reminder_type'] == 'الدواء' && reminder['medication_name'] != null
          ? 'حان وقت ${reminder['reminder_type']} (${reminder['medication_name']})!'
          : 'حان وقت ${reminder['reminder_type']}!',
      scheduledTime: scheduledTime,
      reminderType: _reminderTypeToApiValue[reminder['reminder_type']] ?? reminder['reminder_type'],
      medicationName: reminder['medication_name'],
    );
  }

  void _selectTime(BuildContext context, {TimeOfDay? initialTime, required Function(TimeOfDay) onTimeSelected}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
    final timeParts = reminder['reminder_time'].split(':');
    editTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

    showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل التذكير', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: editReminderType,
                  decoration: InputDecoration(
                    labelText: 'نوع التذكير',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Icon(Icons.notifications, color: Colors.teal),
                  ),
                  items: _reminderTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      editReminderType = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'يرجى اختيار نوع التذكير' : null,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (editReminderType != null && editTime != null) {
                _updateReminder(reminder['id'], editReminderType!, editTime!);
                Navigator.pop(context);
              } else {
                _showSnackBar('يرجى ملء جميع الحقول', Colors.red);
              }
            },
            child: Text('حفظ', style: TextStyle(color: Colors.teal)),
          ),
        ],
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
      transitionDuration: Duration(milliseconds: 300),
    );
  }

  void _showAddReminderDialog() {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إضافة تذكير جديد', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedReminderType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        labelText: 'نوع التذكير',
                        prefixIcon: Icon(Icons.notifications, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: _reminderTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
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
                    SizedBox(height: 16),
                    if (_selectedReminderType == 'الدواء')
                      TextFormField(
                        controller: _medicationController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          labelText: 'اسم الدواء (اختياري)',
                          prefixIcon: Icon(Icons.medical_services, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _medicationName = value.isEmpty ? null : value;
                          });
                        },
                      ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
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
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
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
            child: Text('إضافة', style: TextStyle(color: Colors.teal)),
          ),
        ],
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
      transitionDuration: Duration(milliseconds: 300),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder, int index) {
    final timeParts = reminder['reminder_time'].split(':');
    final time = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

    Color cardColor;
    Color gradientStart;
    IconData iconData;
    switch (reminder['reminder_type']) {
      case 'تحليل السكر':
        cardColor = Colors.redAccent;
        gradientStart = Colors.red[300]!;
        iconData = Icons.bloodtype;
        break;
      case 'الدواء':
        cardColor = Colors.orangeAccent;
        gradientStart = Colors.orange[300]!;
        iconData = Icons.medical_services;
        break;
      case 'شرب الماء':
        cardColor = Colors.blueAccent;
        gradientStart = Colors.blue[300]!;
        iconData = Icons.local_drink;
        break;
      default:
        cardColor = Colors.grey;
        gradientStart = Colors.grey[300]!;
        iconData = Icons.notifications;
    }

    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(iconData, color: cardColor),
          ),
          title: Text(
            reminder['reminder_type'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          subtitle: Text(
            reminder['reminder_type'] == 'الدواء' && reminder['medication_name'] != null
                ? '${_formatTime(time)} - ${reminder['medication_name']}'
                : _formatTime(time),
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () => _showEditDialog(reminder),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('التذكيرات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.teal))
            : _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 80, color: Colors.teal[200]),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد تذكيرات حاليًا',
                          style: TextStyle(fontSize: 20, color: Colors.teal[400]),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.all(16),
                    children: groupedReminders.entries.map((entry) {
                      final reminderType = entry.key;
                      final reminders = entry.value;

                      if (reminders.isEmpty) return SizedBox.shrink();

                      return ExpansionTile(
                        leading: Icon(
                          reminderType == 'تحليل السكر'
                              ? Icons.bloodtype
                              : reminderType == 'الدواء'
                                  ? Icons.medical_services
                                  : Icons.local_drink,
                          color: Colors.teal,
                        ),
                        title: Text(
                          reminderType,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        children: reminders.asMap().entries.map((entry) {
                          final index = entry.key;
                          final reminder = entry.value;
                          return _buildReminderItem(reminder, index);
                        }).toList(),
                        initiallyExpanded: true,
                      );
                    }).toList(),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'إضافة تذكير',
        elevation: 6,
      ),
    );
  }
}