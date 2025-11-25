import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Supabase instance
  final supabase = Supabase.instance.client;

  // signUp
  Future<AuthResponse> signUp(String email, String password) {
    return supabase.auth.signUp(email: email, password: password);
  }

  // logIn
  Future<AuthResponse> logIn(String email, String password) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign Out
  Future<void> signOut() => supabase.auth.signOut();

  // Get all user Seassions
  Session? getSession() => supabase.auth.currentSession;

  // Get current user
  User? getCurrentUser() => supabase.auth.currentUser;

  // Get user's email
  String? getUserEmail() {
    return supabase.auth.currentUser?.email;
  }

  // here it notifies whenever user signs or logs out
  Stream<AuthState> get authChanges => supabase.auth.onAuthStateChange;
}
