class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://luooeidsfkypyctvytok.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1b29laWRzZmt5cHljdHZ5dG9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyMDMzNjcsImV4cCI6MjA2NTc3OTM2N30.kM_S-oLmRTTuBkbpKW2MUn3Ngl7ic0ZaGb-sltYzB0E';

  // Tabelas
  static const String usuariosTable = 'usuarios';
  static const String ongsTable = 'ongs';

  // Rotas
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String ongsListRoute = '/ongs';
  static const String ongDetailsRoute = '/ong-details';
  static const String manageOngsRoute = '/manage-ongs';
  static const String managePostsRoute = '/manage-posts';
  static const String viewPostsRoute = '/view-posts';
}
