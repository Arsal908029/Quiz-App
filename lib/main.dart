import 'package:flutter/material.dart';
import 'package:quiz_master/core/theme/app_theme.dart';
import 'package:quiz_master/data/services/supabase_service.dart';
import 'package:quiz_master/presentation/auth/auth_screen.dart';
import 'package:quiz_master/presentation/home/home_screen.dart';
import 'package:quiz_master/presentation/welcome/welcome_screen.dart';

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
      theme: AppTheme.darkTheme, // Set default theme to dark theme
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force Dark Theme Mode for Cyber Glassmorphism Theme
      debugShowCheckedModeBanner: false,
      initialRoute: '/welcome',
      onGenerateRoute: (settings) {
        // Implement smooth transitions for app routes
        Widget page;
        switch (settings.name) {
          case '/welcome':
            page = const WelcomeScreen();
            break;
          case '/auth':
            page = const AuthScreen();
            break;
          case '/home':
            page = HomeScreen();
            break;
          case '/':
          default:
            page = const AuthWrapper();
            break;
        }

        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
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
      return HomeScreen();
    } else {
      return const AuthScreen();
    }
  }
}