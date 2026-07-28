import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_dimens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firebase_truck_repository.dart';
import 'data/repositories/firebase_schedule_repository.dart';
import 'data/repositories/firebase_reports_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/truck_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/navigation_provider.dart';
import 'splash_screen.dart';
import 'screens/main_shell.dart';
import 'login_screen.dart';

class TrackConnectApp extends StatelessWidget {
  const TrackConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(FirebaseAuthRepository())),
        ChangeNotifierProvider(create: (_) => ScheduleProvider(FirebaseScheduleRepository())),
        ChangeNotifierProvider(create: (_) => TruckProvider(FirebaseTruckRepository())),
        ChangeNotifierProvider(create: (_) => ReportsProvider(FirebaseReportsRepository())),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'TrackConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
              side: const BorderSide(color: Color(0xFFF1F5F9)),
            ),
            color: AppColors.surface,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            centerTitle: false,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (auth.errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text("Database Error: ${auth.errorMessage}"),
                  TextButton(onPressed: () => auth.logout(), child: const Text("Back to Login")),
                ],
              ),
            ),
          );
        }

        if (auth.user != null) {
          return const MainShell();
        }

        return const LoginScreen();
      },
    );
  }
}
