import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class NotificationService {
  // Ganti dengan Project ID yang ada di Firebase Settings Anda jika berbeda
  static const String _projectId = 'notesorder';

  // Fungsi untuk membaca JSON dan membuat Token Akses Sementara (OAuth 2.0)
  static Future<String> _getAccessToken() async {
    // 1. Baca file JSON dari folder assets
    final jsonString = await rootBundle.loadString('assets/service-account.json');
    final accountCredentials = auth.ServiceAccountCredentials.fromJson(jsonString);
    
    // 2. Minta izin akses khusus untuk Firebase Messaging
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // 3. Generate token
    final authClient = await auth.clientViaServiceAccount(accountCredentials, scopes);
    final token = authClient.credentials.accessToken.data;
    authClient.close();
    
    return token;
  }

  static Future<void> kirimNotifKeBoss({
    required String tokenBoss,
    required String title,
    required String body,
  }) async {
    try {
      // Dapatkan token segar
      final String accessToken = await _getAccessToken();
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      // Struktur JSON untuk FCM v1 berbeda dengan yang lama
      final response = await http.post(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': tokenBoss, // Alamat HP Boss
            'notification': {
              'title': title,
              'body': body,
            },
            // Konfigurasi tambahan agar notif bunyi dan muncul sebagai pop-up
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
        print('✅ Dor! Notifikasi berhasil ditembakkan ke HP Boss!');
      } else {
        print('❌ Gagal menembak. Error dari Firebase: ${response.body}');
      }
    } catch (e) {
      print('❌ Terjadi kesalahan sistem saat mengirim notifikasi: $e');
    }
  }
}