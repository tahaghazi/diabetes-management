import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diabetes_management/config/theme.dart';

class PreviousReadingsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> readings;

  const PreviousReadingsScreen({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> readingTypeReverseMap = {
      'FBS': 'صائم',
      'RBS': 'عشوائي',
      'PPBS': 'بعد الأكل',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'القراءات السابقة',
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
        child: readings.isEmpty
            ? Center(
                child: Text(
                  'لا توجد قراءات سابقة',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 20.0), // مسافة بسيطة من الأعلى
                child: Align(
                  alignment: Alignment.topCenter, // تمركز أفقي ووضع الجدول في الأعلى
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: WidgetStateProperty.all(Colors.teal.shade100),
                      dataRowColor: WidgetStateProperty.all(Colors.white),
                      border: TableBorder.all(color: Colors.black, width: 1),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'رقم',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'نوع القياس',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'مستوى السكر',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'التوقيت ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: readings.asMap().entries.map((entry) {
                        int index = entry.key + 1;
                        Map<String, dynamic> reading = entry.value;
                        final DateTime parsedDateTime = DateTime.parse(reading['timestamp']);
                        final String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDateTime);
                        final String formattedTime = DateFormat('h:mm a')
                            .format(parsedDateTime)
                            .replaceAll('AM', 'صباحًا')
                            .replaceAll('PM', 'مساءً');

                        return DataRow(cells: [
                          DataCell(Text(index.toString())),
                          DataCell(Text(readingTypeReverseMap[reading['glucose_type']] ?? 'غير معروف')),
                          DataCell(Text('${reading['glucose_value']} mg/dL')),
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formattedDate),
                              Text(formattedTime),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}