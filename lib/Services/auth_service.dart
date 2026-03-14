import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Supabase instance
  final SupabaseClient _supabase = Supabase.instance.client;

  // Google Sign In Client IDs (IOS and Web)
  static final String webClientId = dotenv.get('webClientId');
  static final String iosClientId = dotenv.get('iosClientId');

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

  // Google Sign In
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // WEB: OAuth Flow
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${Uri.base.origin}/',
      );
    } else {
      // MOBILE: Native Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Initialize Google Sign In
      unawaited(
        googleSignIn.initialize(
          clientId: iosClientId,
          serverClientId: webClientId,
        ),
      );

      final googleAccount = await googleSignIn.authenticate();
      final googleAuthorization = await googleAccount.authorizationClient
          .authorizationForScopes([]);
      final googleAuthentication = googleAccount.authentication;
      final idToken = googleAuthentication.idToken;
      final accessToken = googleAuthorization?.accessToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    }
  }

  // Sign out
  Future<void> signOut() => _supabase.auth.signOut(scope: SignOutScope.global);

  // Get current session
  Session? get session => _supabase.auth.currentSession;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user's email
  String? get userEmail => currentUser?.email;

  // Listen to auth state changes
  Stream<AuthState> get authChanges => _supabase.auth.onAuthStateChange;
}
