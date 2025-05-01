import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart';
import 'package:diabetes_management/services/http_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';

class AlternativeMedicationsScreen extends StatefulWidget {
  const AlternativeMedicationsScreen({super.key});

  @override
  AlternativeMedicationsScreenState createState() => AlternativeMedicationsScreenState();
}

class AlternativeMedicationsScreenState extends State<AlternativeMedicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> filteredMedications = [];
  bool isLoading = false;
  String? errorMessage;
  bool showAlternativeText = false;

  // Instance of HttpService
  final HttpService httpService = HttpService();
  final String baseUrl = "http://192.168.100.6:8000/api";

  // Fetch drug suggestions for Autocomplete
  Future<List<String>> _getDrugSuggestions(String query) async {
    try {
      final response = await httpService.makeRequest(
        method: 'POST',
        url: Uri.parse('$baseUrl/drug-suggestions/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: {'query': query},
      );

      if (response == null) {
        throw Exception('فشل في الاتصال: الرجاء تسجيل الدخول مرة أخرى');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('فشل في جلب اقتراحات الأدوية: ${response.body}');
      }
    } catch (e) {
      throw Exception('خطأ في جلب اقتراحات الأدوية: $e');
    }
  }

  // Fetch alternative medications from the API using HttpService
  Future<void> _searchMedication(String drugName) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      filteredMedications = [];
      showAlternativeText = false;
    });

    try {
      final response = await httpService.makeRequest(
        method: 'POST',
        url: Uri.parse('$baseUrl/alternative-medicine/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: {'drug_name': drugName},
      );

      if (response == null) {
        setState(() {
          errorMessage = 'فشل في الاتصال: الرجاء تسجيل الدخول مرة أخرى';
        });
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result.containsKey('error')) {
          setState(() {
            errorMessage = result['error'];
          });
        } else {
          final List<dynamic> recommendedDrugs = result['recommended_drugs'];
          setState(() {
            filteredMedications = recommendedDrugs.map((drug) => {
                  'name': drug['Drug Name'].toString(),
                  'description': drug['Description'].toString(),
                  'sideEffect': drug['Side Effects'].toString(),
                  'howToUse': drug['How to use with'].toString(),
                }).toList();
            showAlternativeText = true;
          });

          // Check if the widget is still mounted before using BuildContext
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.yellow,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'يرجى اتباع تعليمات الدكتور وإعلامه بالدواء',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 7),
              ),
            );
          }
        }
      } else {
        setState(() {
          errorMessage = 'فشل في جلب الأدوية البديلة: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في الاتصال: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الأدوية البديلة',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TypeAheadField<String>(
                      controller: _searchController,
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'أدخل اسم الدواء الأساسي...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        if (pattern.isEmpty) return [];
                        return await _getDrugSuggestions(pattern);
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSelected: (suggestion) {
                        _searchController.text = suggestion;
                        _searchMedication(suggestion);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_searchController.text.isNotEmpty) {
                              _searchMedication(_searchController.text);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('بحث'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator()),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              if (showAlternativeText && filteredMedications.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    'الأدوية البديلة للدواء المدخل',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: showAlternativeText && filteredMedications.isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.cyan[50], // لون الخلفية السماوي الفاتح
                              borderRadius: BorderRadius.circular(12.0), // زوايا دائرية
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(158, 158, 158, 0.3), // Updated (line 251)
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3), // اتجاه الظل
                                ),
                              ],
                            ),
                            child: DataTable(
                              dividerThickness: 1.5, // سمك الفواصل
                              dataRowMinHeight: 50, // ارتفاع الصف
                              dataRowMaxHeight: 50,
                              columnSpacing: 15, // التباعد بين الأعمدة
                              decoration: BoxDecoration(
                                color: Colors.cyan[50], // لون الخلفية السماوي الفاتح
                                border: Border.all(color: Colors.grey.shade400), // حدود خارجية
                                borderRadius: BorderRadius.circular(12.0), // زوايا دائرية
                              ),
                              border: TableBorder(
                                verticalInside: BorderSide(
                                  width: 1.5,
                                  color: Colors.grey.shade400, // لون الحدود الرأسية
                                ),
                                horizontalInside: BorderSide(
                                  width: 1.5,
                                  color: Colors.grey.shade400, // لون الحدود الأفقية
                                ),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(
                                      'الرقم',
                                      textAlign: TextAlign.center, // محاذاة النص في المنتصف
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, // جعل النص Bold
                                        color: Colors.black, // لون النص أسود
                                        fontSize: 16, // زيادة حجم الخط
                                        letterSpacing: 0.5,
                                        wordSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(
                                      'اسم الدواء',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                        wordSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(
                                      'الوصف',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                        wordSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(
                                      'الأثر الجانبي',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                        wordSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Text(
                                      'طريقة الاستخدام',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                        wordSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              rows: filteredMedications.asMap().entries.map((entry) {
                                int index = entry.key + 1; // الترقيم يبدأ من 1
                                Map<String, String> med = entry.value;
                                return DataRow(
                                  color: WidgetStateProperty.resolveWith<Color?>( // Updated (line 364)
                                    (Set<WidgetState> states) { // Updated (line 365)
                                      // ألوان متناوبة للصفوف
                                      return index % 2 == 0 ? Colors.white : Colors.cyan[50];
                                    },
                                  ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        '$index',
                                        textAlign: TextAlign.center, // محاذاة النص في المنتصف
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        med['name']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(221, 194, 31, 31),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        med['description']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        med['sideEffect']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        med['howToUse']!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}