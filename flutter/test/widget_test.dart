import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_/main.dart'; // تأكد من استيراد DiabetesApp من main.dart

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // بناء التطبيق وتحفيز الإطار.
    await tester.pumpWidget(DiabetesApp()); // استخدم DiabetesApp بدلاً من MyApp

    // التحقق من أن العداد يبدأ من 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // النقر على أيقونة '+' وتحفيز الإطار.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // التحقق من أن العداد تم زيادته.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
