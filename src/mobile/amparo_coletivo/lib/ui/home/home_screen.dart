import 'package:amparo_coletivo/config/settings_controller.dart';
import 'package:amparo_coletivo/routes/app_routes.dart';
import 'package:amparo_coletivo/ui/home/pages/ngos/ngos_page.dart';
import 'package:amparo_coletivo/ui/home/pages/categories/categories_page.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/profile_page.dart';
import 'package:amparo_coletivo/ui/home/pages/admin/admin_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:amparo_coletivo/ui/home/about_us_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/ngos/selected_ngo_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/change_password_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/forgot_password_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/signin_screen.dart';
import 'package:amparo_coletivo/ui/home/pages/profile/signup_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  final List<Widget> _tabs = const [
    NGOsPage(),
    CategoriesPage(),
    ProfilePage(),
    AdminPage(),
    OtherScreensTab(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amparo Coletivo'),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Opções de tema',
            onSelected: settingsController.setThemeMode,
            itemBuilder: (context) => ThemeMode.values
                .map(
                  (mode) => CheckedPopupMenuItem<ThemeMode>(
                    value: mode,
                    checked: settingsController.themeMode == mode,
                    child: Text(_labelForThemeMode(mode)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: -1,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          switch (index) {
            case 0:
              context.push(AppRoutes.about);
              break;
            case 1:
              break;
          }
        },
        header: DrawerHeader(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.diversity_2_rounded, size: 64),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AMPARO',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    Text(
                      'COLETIVO',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '© 2025 Os Três Mosqueteiros',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        children: [
          const NavigationDrawerDestination(
            icon: Icon(Icons.info_outline),
            label: Text('Sobre nós'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.help_outline),
            label: Text('Suporte ao usuário'),
          ),
        ],
      ),
      body: SafeArea(
        child: _tabs[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.diversity_1_outlined),
            selectedIcon: Icon(Icons.diversity_1),
            label: 'ONGs',
            tooltip: 'Aba de ONGs',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorias',
            tooltip: 'Aba de categorias',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
            tooltip: 'Aba de perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Administração',
            tooltip: 'Aba de administração',
          ),
          NavigationDestination(
            icon: Icon(Icons.developer_mode_outlined),
            selectedIcon: Icon(Icons.developer_mode),
            label: 'Desenvolvimento',
            tooltip: 'Aba de desenvolvimento',
          ),
        ],
      ),
    );
  }
}

String _labelForThemeMode(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Tema claro';
    case ThemeMode.dark:
      return 'Tema escuro';
    case ThemeMode.system:
      return 'Tema do sistema';
  }
}

class OtherScreensTab extends StatelessWidget {
  const OtherScreensTab({super.key});

  @override
  Widget build(BuildContext context) {
    final mockedOngData = {
      'id': 1,
      'name': 'ONG de Exemplo',
      'description': 'Uma ONG fictícia para testes',
    };

    final entries = [
      (
        title: 'about_us_screen',
        builder: (context) => AboutUsScreen(ongData: mockedOngData),
      ),
      (
        title: 'selected_ngo_screen',
        builder: (context) => SelectedNGOScreen(ongData: mockedOngData),
      ),
      (
        title: 'change_password',
        builder: (context) => const ChangePasswordScreen(),
      ),
      (
        title: 'forgot_password',
        builder: (context) => const ForgotPasswordScreen(),
      ),
      (
        title: 'signin_screen',
        builder: (context) => const SignInScreen(),
      ),
      (
        title: 'signup_screen',
        builder: (context) => const SignUpScreen(),
      ),
    ];

    return Expanded(
      child: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              child: ListTile(
                title: Text(entry.title),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: entry.builder),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
