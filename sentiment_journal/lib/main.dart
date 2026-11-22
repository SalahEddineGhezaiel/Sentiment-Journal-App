import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/transitions.dart';

// Import screens
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/journal/sentiment_result_screen.dart';
import 'widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to handle navigation
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // Return different MaterialApp based on auth state
        // This ensures proper navigation stack management
        if (user != null) {
          // User is logged in - show app with bottom navigation
          return MaterialApp(
            title: 'Sentiment Journal',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: const AppShell(),
            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case AppRoutes.sentimentResult:
                  page = const SentimentResultScreen();
                  break;
                default:
                  return null;
              }
              return FadeSlidePageRoute(page: page);
            },
          );
        } else {
          // User not logged in - show auth screens
          return MaterialApp(
            title: 'Sentiment Journal',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: const LoginScreen(),
            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case AppRoutes.login:
                  page = const LoginScreen();
                  break;
                case AppRoutes.register:
                  page = const RegisterScreen();
                  break;
                default:
                  return null;
              }
              return FadeSlidePageRoute(page: page);
            },
          );
        }
      },
      loading: () => MaterialApp(
        title: 'Sentiment Journal',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => MaterialApp(
        title: 'Sentiment Journal',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}