import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  factory SupabaseService() => _instance;

  SupabaseService._internal() {
    _client = Supabase.instance.client;
  }

  // -------------------------
  // Auth Methods
  // -------------------------
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return true;
      }
      return false;
    } catch (e) {
      print('Erro ao logar: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Erro ao deslogar: $e');
    }
  }

  // -------------------------
  // User Methods
  // -------------------------
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from(AppConstants.usuariosTable)
        .select()
        .eq('id', user.id)
        .single();

    return response as Map<String, dynamic>?;
  }

  Future<bool> isUserAdmin(String userId) async {
    final response = await _client
        .from(AppConstants.usuariosTable)
        .select('is_admin')
        .eq('id', userId)
        .single();

    return response['is_admin'] ?? false;
  }

  Future<List<Map<String, dynamic>>> getUsuarios() async {
    final response = await _client.from(AppConstants.usuariosTable).select();
    return List<Map<String, dynamic>>.from(response);
  }

  // -------------------------
  // ONG Methods
  // -------------------------
  Future<List<Map<String, dynamic>>> getOngs() async {
    final response = await _client.from(AppConstants.ongsTable).select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getOngById(String id) async {
    final response = await _client
        .from(AppConstants.ongsTable)
        .select()
        .eq('id', id)
        .single();

    return response;
  }
}
