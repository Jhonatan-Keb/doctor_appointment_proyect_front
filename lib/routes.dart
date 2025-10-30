import 'screens/appointmens.dart';
import 'package:flutter/material.dart';
import 'screens/appointment_home.dart';
import 'screens/profile_page.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';
import 'screens/advice.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String consejos = '/consejos';
    static const String citas = '/citas';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    home: (context) => const AppointmentHomePage(),
    profile: (context) => const ProfilePage(),
    consejos: (context) => const HealthTipsPage(),
    citas: (context) => const MyAppointmentsPage(),
     
  };
}