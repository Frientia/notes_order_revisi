import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart'; 
import 'core/routes/app_router.dart';

// 1. FUNGSI PENJAGA LATAR BELAKANG (Wajib ditaruh di luar class manapun / Top-Level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase sudah diinisialisasi sebelum memproses notif background
  await Firebase.initializeApp();
  print("Notifikasi masuk saat aplikasi ditutup: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
    print("Firebase berhasil diinisialisasi");
  } catch (e) {
    print("Error inisialisasi Firebase: $e");
  }

  try {
    await Supabase.initialize(
      url: 'https://xgfrgggaslqgmpixogxb.supabase.co/',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhnZnJnZ2dhc2xxZ21waXhvZ3hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk0MzkwMDgsImV4cCI6MjA5NTAxNTAwOH0.jO9_IZuh8bipQ58NENIoZm_noss4uCnUXOjBRnGD730', // GANTI DENGAN KEY ASLI ANDA
    );
    print("Supabase berhasil diinisialisasi");
  } catch (e) {
    print("Error inisialisasi Supabase: $e");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Sistem Pencatatan PT Lahir Barutama',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}