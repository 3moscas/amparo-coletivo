import 'package:flutter/material.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // -------------------------
  // Initialize auth state
  // -------------------------
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _supabaseService.getCurrentUser();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------
  // Sign in
  // -------------------------
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _supabaseService.signInWithEmail(email, password);

      if (!success) {
        _error = 'Credenciais inválidas';
        return false;
      }

      _currentUser = await _supabaseService.getCurrentUser();

      if (_currentUser == null) {
        _error = 'Falha ao buscar dados do usuário';
        return false;
      }

      return true;
    } catch (e) {
      _error = 'Ocorreu um erro inesperado';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------
  // Sign out
  // -------------------------
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _currentUser = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------
  // Check if user is admin
  // -------------------------
  Future<bool> isAdmin() async {
    if (_currentUser == null) return false;
    return await _supabaseService.isUserAdmin(_currentUser!['id']);
  }
}
