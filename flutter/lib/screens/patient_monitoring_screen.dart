import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:diabetes_management/config/theme.dart';
import 'patient_health_record_screen.dart';

class PatientMonitoringScreen extends StatefulWidget {
  const PatientMonitoringScreen({super.key});

  @override
  PatientMonitoringScreenState createState() => PatientMonitoringScreenState();
}

class PatientMonitoringScreenState extends State<PatientMonitoringScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HttpService().makeRequest(
        method: 'GET',
        url: Uri.parse('http://192.168.100.6:8000/api/my-patients/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('تجاوز مهلة الاتصال بالسيرفر');
      });

      if (response == null) {
        setState(() {
          _errorMessage = 'فشل الاتصال بالسيرفر';
          _isLoading = false;
        });
        return;
      }

      debugPrint('My Patients Response Status: ${response.statusCode}');
      debugPrint('My Patients Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _patients = List<Map<String, dynamic>>.from(responseData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل تحميل بيانات المرضى: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Patients Error: $e');
      setState(() {
        _errorMessage = 'حدث خطأ أثناء جلب المرضى: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة المرضى'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.appBarGradient,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchPatients,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : _patients.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد مرضى متربطين حاليًا',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.teal,
                                size: 40,
                              ),
                              title: Text(
                                '${patient['first_name'] ?? 'غير متوفر'} ${patient['last_name'] ?? ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              subtitle: Text(
                                patient['email'] ?? 'غير متوفر',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientHealthRecordScreen(
                                      patientId: patient['id'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}