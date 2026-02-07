import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Supabase instance
  final SupabaseClient _supabase = Supabase.instance.client;

  // get Supabase client
  SupabaseClient get supabaseClient => _supabase;

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) {
    return _supabase.auth.signUp(email: email, password: password);
  }

  // Log in with email and password
  Future<AuthResponse> logIn(String email, String password) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() => _supabase.auth.signOut();

  // Get current session
  Session? get session => _supabase.auth.currentSession;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user's email
  String? get userEmail => currentUser?.email;

  // Listen to auth state changes
  Stream<AuthState> get authChanges => _supabase.auth.onAuthStateChange;
}
