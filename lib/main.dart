import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'login.dart';
import 'signup.dart';
import 'home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


late final SupabaseClient supabase;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // SupabaseClient 직접 초기화
  supabase = SupabaseClient(
    'https://zsfxqsqvmbhritorvlkd.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzZnhxc3F2bWJocml0b3J2bGtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc2NDM3ODAsImV4cCI6MjA2MzIxOTc4MH0.s9RDuDvBpiid1cfqyy0Hf6OH-fBJ7q8E18yVoMb0SS0',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Store App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/home': (context) => HomePage(),
      },
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko'), // 한국어
        const Locale('en'), // 영어 (기본)
      ],
    );
  }
}
