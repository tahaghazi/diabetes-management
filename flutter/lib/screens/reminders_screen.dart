import 'dart:async';
import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _medicationController = TextEditingController();
  TimeOfDay? _selectedTime;
  List<String> reminders = [
    "💧 تذكير بشرب الماء كل 3 ساعات",
    "🩸 تذكير بإجراء تحليل السكر كل 20 يومًا"
  ];
  Timer? waterTimer;
  Timer? glucoseTimer;

  @override
  void initState() {
    super.initState();
    _startWaterReminder();
    _startGlucoseTestReminder();
  }

  @override
  void dispose() {
    waterTimer?.cancel();
    glucoseTimer?.cancel();
    super.dispose();
  }

  void _startWaterReminder() {
    waterTimer = Timer.periodic(Duration(hours: 3), (timer) {
      if (mounted) {
        setState(() {
          reminders.add("💧 حان وقت شرب الماء للحفاظ على الترطيب!");
        });
      }
    });
  }

  void _startGlucoseTestReminder() {
    glucoseTimer = Timer.periodic(Duration(days: 20), (timer) {
      if (mounted) {
        setState(() {
          reminders.add("🩸 تذكير: قم بإجراء تحليل السكر اليوم!");
        });
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final String period = time.period == DayPeriod.am ? "صباحًا" : "مساءً";
    return "${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} $period";
  }

  void _addMedicationReminder() {
    if (_medicationController.text.isNotEmpty && _selectedTime != null) {
      setState(() {
        reminders.add("💊 ${_medicationController.text} عند ${_formatTime(_selectedTime!)}");
        _medicationController.clear();
        _selectedTime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة التذكير بنجاح!')),
      );
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التذكيرات')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إضافة تذكير للدواء:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _medicationController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اسم الدواء',
                prefixIcon: Icon(Icons.medication),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime(context),
                    child: Text(_selectedTime == null ? 'اختر الوقت' : 'التذكير: ${_formatTime(_selectedTime!)}'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addMedicationReminder,
              child: Text('إضافة التذكير'),
            ),
            SizedBox(height: 20),
            Text('التذكيرات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.notifications, color: Colors.blue),
                    title: Text(reminders[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}