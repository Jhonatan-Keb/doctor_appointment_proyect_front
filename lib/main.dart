import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HouseMD Usuarios',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      // ===== TEMA CLARO =====
      theme: ThemeData(
        useMaterial3: true,
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0891B2),
          brightness: Brightness.light,
          primary: const Color(0xFF0891B2),
          primaryContainer: const Color(0xFFCFFAFE),
          secondary: const Color(0xFF06B6D4),
          secondaryContainer: const Color(0xFFE0F2FE),
          tertiary: const Color(0xFF14B8A6),
          surface: Colors.white,
          surfaceVariant: const Color(0xFFF0F9FF),
          error: const Color(0xFFDC2626),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: const Color(0xFF475569),
          outline: const Color(0xFFCBD5E1),
        ),

        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFF0891B2),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.15,
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.1),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            backgroundColor: const Color(0xFF0891B2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            side: const BorderSide(color: Color(0xFF0891B2), width: 1.5),
            foregroundColor: const Color(0xFF0891B2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            // ✨ Mejora: Feedback visual en hover/press
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFF0891B2).withOpacity(0.12);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFF0891B2).withOpacity(0.08);
                }
                return null;
              },
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1F5F9),
          selectedColor: const Color(0xFF0891B2),
          disabledColor: const Color(0xFFE2E8F0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // ✨ Mejora: Animación de selección
          showCheckmark: true,
          checkmarkColor: Colors.white,
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF0891B2),
          unselectedItemColor: Color(0xFF94A3B8),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Color(0xFF64748B),
          size: 24,
        ),

        dividerTheme: const DividerThemeData(
          color: Color(0xFFE2E8F0),
          thickness: 1,
          space: 1,
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: -0.25,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF334155),
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF475569),
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),

        // ✨ Mejora: Configuración de animaciones
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      // ===== TEMA OSCURO =====
      darkTheme: ThemeData(
        useMaterial3: true,
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6D4),
          brightness: Brightness.dark,
          primary: const Color(0xFF06B6D4),
          primaryContainer: const Color(0xFF164E63),
          secondary: const Color(0xFF22D3EE),
          secondaryContainer: const Color(0xFF155E75),
          tertiary: const Color(0xFF2DD4BF),
          surface: const Color(0xFF1E293B),
          surfaceVariant: const Color(0xFF334155),
          error: const Color(0xFFEF4444),
          onPrimary: const Color(0xFF0F172A),
          onSecondary: const Color(0xFF0F172A),
          onSurface: const Color(0xFFF1F5F9),
          onSurfaceVariant: const Color(0xFFCBD5E1),
          outline: const Color(0xFF475569),
        ),

        scaffoldBackgroundColor: const Color(0xFF0F172A),

        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Color(0xFFF1F5F9),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
            letterSpacing: 0.15,
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E293B),
          shadowColor: Colors.black.withOpacity(0.3),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            backgroundColor: const Color(0xFF06B6D4),
            foregroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.black.withOpacity(0.1);
                }
                if (states.contains(WidgetState.hovered)) {
                  return Colors.black.withOpacity(0.05);
                }
                return null;
              },
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            side: const BorderSide(color: Color(0xFF06B6D4), width: 1.5),
            foregroundColor: const Color(0xFF06B6D4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFF06B6D4).withOpacity(0.12);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0xFF06B6D4).withOpacity(0.08);
                }
                return null;
              },
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF334155),
          selectedColor: const Color(0xFF06B6D4),
          disabledColor: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFCBD5E1),
          ),
          secondaryLabelStyle: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          showCheckmark: true,
          checkmarkColor: Color(0xFF0F172A),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          backgroundColor: Color(0xFF1E293B),
          selectedItemColor: Color(0xFF06B6D4),
          unselectedItemColor: Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Color(0xFF94A3B8),
          size: 24,
        ),

        dividerTheme: const DividerThemeData(
          color: Color(0xFF334155),
          thickness: 1,
          space: 1,
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF1F5F9),
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF1F5F9),
            letterSpacing: -0.25,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFFCBD5E1),
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF94A3B8),
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
        ),

        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}