import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:diabetes_management/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class MedicationConfirmationScreen extends StatefulWidget {
  final int notificationId;
  final String title;
  final String body;
  final String? medicationName;

  const MedicationConfirmationScreen({
    super.key,
    required this.notificationId,
    required this.title,
    required this.body,
    this.medicationName,
  });

  @override
  MedicationConfirmationScreenState createState() =>
      MedicationConfirmationScreenState();
}

class MedicationConfirmationScreenState
    extends State<MedicationConfirmationScreen> {
  bool _isLoading = false;
  final Logger _logger = Logger();

  Future<void> _confirmMedication() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> loggedNotifications =
          prefs.getStringList('logged_notifications') ?? [];

      Map<String, dynamic> notificationData = {
        'id': widget.notificationId,
        'title': widget.title,
        'body': widget.body,
        'reminder_type': 'medication',
        'scheduled_time': DateTime.now().toIso8601String(),
        'received_time': DateTime.now().toIso8601String(),
        'medication_name': widget.medicationName,
        'taken': true,
        'taken_time': DateTime.now().toIso8601String(),
      };

      loggedNotifications.add(jsonEncode(notificationData));
      await prefs.setStringList('logged_notifications', loggedNotifications);
      _logger.i('تم تسجيل تناول الدواء: ${widget.medicationName}');

      await NotificationService.cancelNotification(widget.notificationId);

      if (!mounted) return;
      _showSnackBar('تم تسجيل تناول الدواء بنجاح!', Colors.green);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل تسجيل تناول الدواء: $e', Colors.red);
      _logger.e('فشل تسجيل تناول الدواء: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            'تأكيد تناول الدواء',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9, // Larger card width
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.body,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              color: Colors.grey[800],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.medicationName != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'اسم الدواء: ${widget.medicationName}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            )
                          : ElevatedButton(
                              onPressed: _confirmMedication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'تم تناول الدواء',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}