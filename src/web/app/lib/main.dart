import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/services/auth_service.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

// Global AuthService instance to ensure session persistence
late final AuthService authService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize AuthService and restore session
  authService = AuthService();
  await authService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: MyApp(authService: authService),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _appRouter;

  @override
  void initState() {
    super.initState();

    _appRouter = GoRouter(
      initialLocation: widget.authService.isAuthenticated
          ? AppConstants.dashboardRoute
          : AppConstants.loginRoute,
      redirect: (context, state) {
        final isAuthenticated = widget.authService.isAuthenticated;
        final isLoggingIn = state.matchedLocation == AppConstants.loginRoute;

        // If not authenticated and not on login page, redirect to login
        if (!isAuthenticated && !isLoggingIn) {
          return AppConstants.loginRoute;
        }

        // If authenticated and on login page, redirect to dashboard
        if (isAuthenticated && isLoggingIn) {
          return AppConstants.dashboardRoute;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppConstants.loginRoute,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConstants.dashboardRoute,
          builder: (context, state) => const DashboardScreen(),
        ),
        // Add other routes here
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Error: ${state.error}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ONG Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _appRouter,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return FutureBuilder(
      future: authService.initialize(),
      builder: (context, snapshot) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.isAuthenticated) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
