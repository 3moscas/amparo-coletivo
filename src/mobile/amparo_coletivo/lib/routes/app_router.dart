import 'package:amparo_coletivo/ui/home/pages/profile/profile_page.dart';
import 'package:go_router/go_router.dart';

import 'package:amparo_coletivo/routes/app_routes.dart';
import 'package:amparo_coletivo/ui/home/home_screen.dart';
import 'package:amparo_coletivo/ui/home/about_us_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/signin_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/signup_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/forgot_password_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/change_password_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/admin/admin_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.signin,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) {
          final extra = state.extra;
          final Map<String, dynamic> defaultData = {
            'title': 'Amparo Coletivo',
            'description':
                'O Amparo Coletivo é uma plataforma dedicada a conectar ONGs e pessoas que desejam ajudar. Nosso objetivo é facilitar o acesso a informações sobre ONGs, promovendo a transparência e a solidariedade.',
            'image_url':
                'https://luooeidsfkypyctvytok.supabase.co/storage/v1/object/public/amparo_coletivo/Amparo_Coletivo-logo.png',
            'contactEmail': 'AmparoColetivo.suporte@gmail.com',
          };
          final ongData = extra is Map<String, dynamic> ? extra : defaultData;
          return AboutUsScreen(ongData: ongData);
        },
      ),
    ],
  );
}
