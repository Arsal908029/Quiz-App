import 'package:flutter/material.dart';
import 'package:quiz_master/core/theme/app_theme.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:quiz_master/presentation/auth/auth_screen.dart';
import 'package:quiz_master/presentation/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const QuizMasterApp());
}

class QuizMasterApp extends StatelessWidget {
  const QuizMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Master',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => HomeScreen(), // REMOVED const
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;
    
    if (user != null) {
      return HomeScreen(); // REMOVED const
    } else {
      return const AuthScreen();
    }
  }
}