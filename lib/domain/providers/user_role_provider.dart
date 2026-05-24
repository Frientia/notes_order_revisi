import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

// FutureProvider untuk mengambil role dari Supabase berdasarkan UID Firebase
final userRoleProvider = FutureProvider<String?>((ref) async {
  // 1. Pantau status user dari Firebase
  final user = ref.watch(authStateProvider).value;
  
  if (user == null) {
    return null; // Jika belum login, role kosong
  }

  // 2. Query ke Supabase untuk mencari role
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('users')
        .select('role')
        .eq('firebase_uid', user.uid)
        .maybeSingle();
        
    return response?['role'] as String?;
  } catch (e) {
    // Handle error (misal: RTO atau user belum terdaftar di tabel users)
    return null; 
  }
});