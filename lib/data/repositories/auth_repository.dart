import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, Supabase.instance.client);
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabase;

  AuthRepository(this._firebaseAuth, this._supabase);

  Future<void> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      throw Exception('Terjadi kesalahan yang tidak diketahui: $e');
    }
  }

  Future<void> registerPetugas(String nama, String email, String password) async {
    try {
      UserCredential cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await cred.user!.sendEmailVerification();

        await _supabase.from('users').insert({
          'firebase_uid': cred.user!.uid,
          'nama_user': nama,
          'email': email,
          'role': 'petugas',
          'email_verified': false,
        });
        
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    } catch (e) {
      await _firebaseAuth.currentUser?.delete();
      throw Exception('Gagal sinkronisasi data: $e');
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Email tidak terdaftar.';
      case 'wrong-password': return 'Password salah.';
      case 'email-already-in-use': return 'Email sudah digunakan.';
      case 'invalid-email': return 'Format email tidak valid.';
      default: return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }
}