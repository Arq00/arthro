import 'package:arthro/admin/controllers/admin_dashboard_controller.dart';
import 'package:arthro/admin/controllers/admin_user_controller.dart';
import 'package:arthro/admin/view/admin_dasbhoard_views.dart';
import 'package:arthro/controllers/auth_controller.dart';
import 'package:arthro/firebase_options.dart';
import 'package:arthro/views/appointment/appointment_form_view.dart';
import 'package:arthro/views/medication/medication_add_form.dart';
import 'package:arthro/views/medication/medication_main_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/services/notification_service.dart';

import 'package:arthro/controllers/medication_controller.dart';
import 'package:arthro/controllers/appointment_controller.dart';

import 'package:arthro/views/navigation/global_navigation.dart'; // globalNavKey lives here
import 'package:arthro/views/appointment/appointment_main_view.dart';
import 'package:arthro/views/profile/profile_view.dart';
import 'package:arthro/views/auth/welcome_view.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  //await NotificationService.init();
  if (!kIsWeb) await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => MedicationController()),
        ChangeNotifierProvider(create: (_) => AppointmentController()),

        //Admin
        ChangeNotifierProvider(create: (_) => AdminDashboardController()),
        ChangeNotifierProvider(create: (_) => AdminUserController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color brandTeal = Color(0xFF1B5F5F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, 
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      title: 'ArthroCare',
      theme: ThemeData(
        primaryColor: brandTeal,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandTeal,
            side: const BorderSide(color: brandTeal, width: 2),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIconColor: brandTeal,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandTeal, width: 2),
          ),
        ),
      ),
      home: kIsWeb 
  ? const AdminDashboardView()                    // WEB = ALWAYS ADMIN 🎉
  : StreamBuilder<User?>(                         // MOBILE = normal user auth
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1B5F5F)),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data!.emailVerified) {
      return GlobalNavigation(key: globalNavKey);
    }
        return const WelcomeView();
      },
    ),


      routes: {
        
      // EXISTING USER ROUTES (unchanged)
      '/appointment_main':   (_) => const AppointmentMainView(),
      '/appointment_form':   (_) => const AppointmentFormView(),
      '/medication_main':    (_) => const MedicationMainView(),
      '/medication_form':    (_) => const MedicationAddView(),
      '/profile':            (_) => const ProfileView(),
      
      // NEW ADMIN ROUTES
      '/admin/dashboard':    (_) => const AdminDashboardView(),
      //'/admin/users':        (_) => const AdminUserListView(),

      },
    );
  }

  // Add this BEFORE the final closing brace of main.dart file
  Future<bool> _isAdminUser(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      return userDoc['role'] == 'admin' || userDoc['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

}