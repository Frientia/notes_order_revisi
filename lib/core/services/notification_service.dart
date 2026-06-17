import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  // Ganti dengan Project ID yang ada di Firebase Settings Anda jika berbeda
  static const String _projectId = 'notesorder';
  
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fungsi untuk membaca JSON dan membuat Token Akses Sementara (OAuth 2.0)
  static Future<String> _getAccessToken() async {
    final jsonString = await rootBundle.loadString('assets/service-account.json');
    final accountCredentials = auth.ServiceAccountCredentials.fromJson(jsonString);
    
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final authClient = await auth.clientViaServiceAccount(accountCredentials, scopes);
    final token = authClient.credentials.accessToken.data;
    authClient.close();
    
    return token;
  }

  /// Menembak notifikasi ke Database (Supabase) SEKALIGUS ke HP (Firebase Cloud Messaging)
  Future<void> kirimNotifDanPush({
    required String tipeNotif, // 'PENCATATAN', 'PENCATATAN_HUTANG', 'REMINDER_HUTANG', 'PELUNASAN'
    required int idPencatatan,
    int? idDetail,
    required String judul,
    required String pesan,
    required String? tokenBoss, // Fcm token dari tabel user (Bisa null jika Bos belum login/belum punya token)
  }) async {
    
    // ==========================================
    // 1. SIMPAN KE DATABASE SUPABASE (KOTAK MASUK)
    // ==========================================
    try {
      await _supabase.from('notifikasi').insert({
        'tipe_notif': tipeNotif,
        'id_pencatatan': idPencatatan,
        'id_detail_pencatatan': idDetail,
        'judul': judul,
        'pesan': pesan,
      });
      print('✅ Database: Notifikasi $tipeNotif berhasil disimpan!');
    } catch (e) {
      print('❌ Database: Gagal menyimpan notifikasi ke Supabase: $e');
    }

    // ==========================================
    // 2. KIRIM PUSH NOTIFICATION (BUNYI DI HP)
    // ==========================================
    if (tokenBoss == null || tokenBoss.isEmpty) {
      print('⚠️ Push FCM: Token Boss kosong. Push notif layar tidak dikirim.');
      return; // Berhenti di sini, tidak perlu nembak Firebase
    }

    try {
      final String accessToken = await _getAccessToken();
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': tokenBoss, 
            'notification': {
              'title': judul,
              'body': pesan,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
              }
            }
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Push FCM: Dor! Notifikasi berhasil ditembakkan ke HP Boss!');
      } else {
        print('Push FCM: Gagal menembak. Error: ${response.body}');
      }
    } catch (e) {
      print('Push FCM: Terjadi kesalahan sistem saat mengirim notifikasi: $e');
    }
  }
}