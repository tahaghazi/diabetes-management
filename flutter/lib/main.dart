import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/glucose_tracking_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/awareness_screen.dart';
import 'screens/alternative_medications_screen.dart';
import 'screens/account_type_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/medication_confirmation_screen.dart';
import 'package:diabetes_management/services/notification_service.dart';
import 'package:diabetes_management/services/user_provider.dart';
import 'config/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(navigatorKey: navigatorKey);
  runApp(const DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Diabetes Management',
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorObservers: [routeObserver],
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/glucose_tracking': (context) => const GlucoseTrackingScreen(),
          '/reminders': (context) => const RemindersScreen(),
          '/ai_analysis': (context) => const AIAnalysisScreen(),
          '/profile_settings': (context) => const ProfileScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/reset_password': (context) => ResetPasswordScreen(
                email: ModalRoute.of(context)!.settings.arguments as String,
              ),
          '/Awareness': (context) => const AwarenessScreen(),
          '/alternative_medications': (context) =>
              const AlternativeMedicationsScreen(),
          '/account_type': (context) => const AccountTypeScreen(),
          '/medication_confirmation': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return MedicationConfirmationScreen(
              notificationId: args['notificationId'],
              title: args['title'],
              body: args['body'],
              medicationName: args['medicationName'],
            );
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/sign_up') {
            final role = settings.arguments as String? ?? 'مريض';
            return MaterialPageRoute(
              builder: (context) => SignUpScreen(accountType: role),
            );
          }
          return null;
        },
      ),
    );
  }
}