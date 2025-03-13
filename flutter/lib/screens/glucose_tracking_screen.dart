import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GlucoseTrackingScreen extends StatefulWidget {
  @override
  _GlucoseTrackingScreenState createState() => _GlucoseTrackingScreenState();
}

class _GlucoseTrackingScreenState extends State<GlucoseTrackingScreen> {
  final TextEditingController _glucoseController = TextEditingController();
  List<Map<String, String>> glucoseReadings = [];
  void _addGlucoseReading() {
    if (_glucoseController.text.isNotEmpty) {
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      setState(() {
        glucoseReadings.add({
          'value': _glucoseController.text,
          'date': formattedDate,
        });
        _glucoseController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة القراءة بنجاح!')),
      );
    }
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
              'أدخل مستوى السكر:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            ElevatedButton(
              onPressed: _addGlucoseReading,
              child: Text('حفظ القراءة'),
            ),
            SizedBox(height: 20),
            Text(
              'القراءات السابقة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: glucoseReadings.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.water_drop, color: Colors.blue),
                    title: Text('${glucoseReadings[index]['value']} mg/dL'),
                    subtitle: Text('تاريخ التسجيل: ${glucoseReadings[index]['date']}'),
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

