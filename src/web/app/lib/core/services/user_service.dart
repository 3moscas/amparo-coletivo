import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Buscar todos os usuários
  Future<List<UserModel>> getUsers() async {
    final response = await _supabase
        .from(AppConstants.usuariosTable)
        .select()
        .order('first_name');

    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  /// Criar novo usuário (auth + registro na tabela usuarios)
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    String? bio,
    bool isAdmin = false,
  }) async {
    // 1. Criar usuário no auth do Supabase
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final authUser = authResponse.user;
    if (authUser == null) {
      throw Exception('Falha ao criar usuário de autenticação.');
    }

    // 2. Inserir registro na tabela usuarios com o ID do auth
    final data = {
      'id': authUser.id,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'email': email,
      'bio': bio,
      'is_admin': isAdmin,
    };

    final inserted = await _supabase
        .from(AppConstants.usuariosTable)
        .insert(data)
        .select()
        .single();

    return UserModel.fromJson(inserted);
  }

  /// Atualizar usuário
  Future<UserModel> updateUser(UserModel user) async {
    final data = user.toJson();

    // Manter campos de avatar apenas se existirem
    if (data['avatar_url'] == null) data.remove('avatar_url');
    if (data['avatar_path'] == null) data.remove('avatar_path');

    data['is_admin'] = user.isAdmin;
    data.remove('isAdmin');

    final updated = await _supabase
        .from(AppConstants.usuariosTable)
        .update(data)
        .eq('id', user.id)
        .select()
        .single();

    return UserModel.fromJson(updated);
  }

  /// Deletar usuário
  Future<void> deleteUser(String id) async {
    await _supabase.from(AppConstants.usuariosTable).delete().eq('id', id);
  }
}
