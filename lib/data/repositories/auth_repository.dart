import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, Supabase.instance.client);
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabase;

  AuthRepository(this._firebaseAuth, this._supabase);

  Future<void> login(String email, String password) async {
    try {
      // 1. Simpan hasil login ke dalam variabel cred (UserCredential)
      UserCredential cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. LOGIKA BARU: Simpan Token FCM jika login berhasil
      if (cred.user != null) {
        try {
          // Minta izin memunculkan notifikasi di HP
          await FirebaseMessaging.instance.requestPermission();
          
          // Ambil token unik dari HP yang sedang digunakan
          String? tokenFCM = await FirebaseMessaging.instance.getToken();
          
          if (tokenFCM != null) {
            // Simpan token ke tabel users di Supabase berdasarkan firebase_uid
            await _supabase
                .from('users')
                .update({'fcm_token': tokenFCM})
                .eq('firebase_uid', cred.user!.uid); 
                
            print("FCM Token berhasil disimpan ke database: $tokenFCM");
          }
        } catch (e) {
          // Jika sekadar gagal ambil token, login harus tetap berjalan normal
          print("Peringatan: Gagal menyimpan FCM token: $e");
        }
      }
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
          // fcm_token tidak perlu diisi saat register, biarkan terisi saat dia login
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