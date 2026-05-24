import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Pastikan file ini sudah ter-generate dari perintah flutterfire configure
import 'firebase_options.dart'; 
import 'core/routes/app_router.dart';

void main() async {
  // Pastikan binding Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Gunakan try-catch agar jika gagal, errornya terlihat jelas di Console
  try {
    await Firebase.initializeApp(
      // Wajib menggunakan options jika di-run di Web
      options: DefaultFirebaseOptions.currentPlatform, 
    );
    print("Firebase berhasil diinisialisasi");
  } catch (e) {
    print("Error inisialisasi Firebase: $e");
  }

  try {
    await Supabase.initialize(
      url: 'https://xgfrgggaslqgmpixogxb.supabase.co/', // GANTI DENGAN URL ASLI ANDA
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhnZnJnZ2dhc2xxZ21waXhvZ3hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk0MzkwMDgsImV4cCI6MjA5NTAxNTAwOH0.jO9_IZuh8bipQ58NENIoZm_noss4uCnUXOjBRnGD730', // GANTI DENGAN KEY ASLI ANDA
    );
    print("Supabase berhasil diinisialisasi");
  } catch (e) {
    print("Error inisialisasi Supabase: $e");
  }

  // 3. Jalankan aplikasi
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
    );
  }
}