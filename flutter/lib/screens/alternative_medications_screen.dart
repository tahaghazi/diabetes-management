import 'package:flutter/material.dart';
import 'package:diabetes_management/config/theme.dart';

class AlternativeMedicationsScreen extends StatefulWidget {
  const AlternativeMedicationsScreen({super.key});

  @override
  AlternativeMedicationsScreenState createState() => AlternativeMedicationsScreenState();
}

class AlternativeMedicationsScreenState extends State<AlternativeMedicationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> medications = [
    {
      'name': 'انسولين',
      'description': 'الوصف',
      'sideEffect': 'أثر جانبي',
      'howToUse': 'يؤخذ مع الماء'
    },
  ];
  List<Map<String, String>> filteredMedications = [];
  bool showAlternativeText = false;

  @override
  void initState() {
    super.initState();
    filteredMedications = medications;
  }

  void _searchMedication(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMedications = medications;
        showAlternativeText = false;
      } else {
        filteredMedications = medications
            .where((med) =>
                med['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
        showAlternativeText = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.yellow,
              size: 30,
            ),
            const SizedBox(width: 10),
            const Text(
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
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'أدخل اسم الدواء الأساسي...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _searchMedication(_searchController.text);
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
              if (showAlternativeText) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    'الأدوية البديلة للدواء المدخل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'نتائج البحث عن الأدوية البديلة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      dividerThickness: 2.0,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 60,
                      columnSpacing: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      border: TableBorder(
                        verticalInside: BorderSide(
                          width: 2.0,
                          color: Colors.grey,
                        ),
                        horizontalInside: BorderSide(
                          width: 2.0,
                          color: Colors.grey,
                        ),
                      ),
                      columns: const [
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'اسم الدواء',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'الوصف',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'الأثر الجانبي',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: ColoredBox(
                            color: Colors.teal,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'طريقة الاستخدام',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      rows: filteredMedications.map((med) {
                        return DataRow(
                          cells: [
                            DataCell(Text(med['name']!)),
                            DataCell(Text(med['description']!)),
                            DataCell(Text(med['sideEffect']!)),
                            DataCell(Text(med['howToUse']!)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}