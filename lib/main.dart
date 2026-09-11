import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OsamaPhoneApp());
}

class OsamaPhoneApp extends StatelessWidget {
  const OsamaPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أسامة فون - Osama Phone',
      debugShowCheckedModeBanner: false,
      // دعم اللغة العربية والاتجاه من اليمين لليسار (RTL)
      locale: const Locale('ar', 'IQ'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'IQ'),
        Locale('en', 'US'),
      ],
      // الثيم العام للتطبيق بتصميم داكن فاخر وعصري (Premium Modern Dark Theme)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19), // كحلي غامق فخم
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0EA5E9), // أزرق سماوي مضيء
          secondary: Color(0xFF10B981), // أخضر زمردي للأسعار والواتساب
          surface: Color(0xFF161F30), // خلفية الكروت والبطاقات
          background: Color(0xFF0B0F19),
          error: Color(0xFFEF4444),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
          titleLarge: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
          bodyMedium: GoogleFonts.cairo(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111827),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF161F30),
          elevation: 4,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFF1E293B), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
