import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GlucoseTrackingScreen extends StatefulWidget {
  const GlucoseTrackingScreen({super.key});

  @override
  GlucoseTrackingScreenState createState() => GlucoseTrackingScreenState();
}

class GlucoseTrackingScreenState extends State<GlucoseTrackingScreen> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _selectedReadingType = 'صائم'; // Default reading type
  List<Map<String, String>> glucoseReadings = [];

  Future<void> _selectDateTime(BuildContext context) async {
    if (!mounted) return; // فحص مبكر لـ mounted قبل أي عملية

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) return; // فحص mounted بعد أول await

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return; // فحص mounted بعد ثاني await

    final DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDateTime);
    final String formattedTime = DateFormat('h:mm a').format(pickedDateTime).replaceAll('AM', 'صباحًا').replaceAll('PM', 'مساءً');

    setState(() {
      _dateController.text = formattedDate;
      _timeController.text = formattedTime;
    });
  }

  void _addGlucoseReading() {
    if (_glucoseController.text.isNotEmpty &&
        _dateController.text.isNotEmpty &&
        _timeController.text.isNotEmpty) {
      String formattedDateTime =
          '${_dateController.text} ${_timeController.text}';

      setState(() {
        glucoseReadings.add({
          'value': _glucoseController.text,
          'date': formattedDateTime,
          'type': _selectedReadingType,
        });
        _glucoseController.clear();
        _dateController.clear();
        _timeController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة القراءة بنجاح!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى ملء جميع الحقول!')),
      );
    }
  }

  void _deleteReading(int index) {
    setState(() {
      glucoseReadings.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حذف القراءة بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تتبع مستوى السكر')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أدخل مستوى السكر',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _glucoseController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'مستوى السكر (mg/dL)',
                prefixIcon: Icon(Icons.monitor_heart),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () => _selectDateTime(context),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'الوقت',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () => _selectDateTime(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedReadingType,
              items: ['صائم', 'قبل الأكل', 'بعد الأكل']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReadingType = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'نوع القراءة',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addGlucoseReading,
              child: Text('حفظ القراءة'),
            ),
            SizedBox(height: 20),
            Text(
              ':القراءات السابقة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: glucoseReadings.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: Icon(Icons.water_drop, color: Colors.blue),
                      title: Text('${glucoseReadings[index]['value']} mg/dL'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تاريخ التسجيل: ${glucoseReadings[index]['date']}'),
                          Text('نوع القراءة: ${glucoseReadings[index]['type']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteReading(index),
                      ),
                    ),
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