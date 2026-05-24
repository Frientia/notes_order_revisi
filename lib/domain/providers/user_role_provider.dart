import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  
  if (user == null) {
    return null; 
  }

  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('users')
        .select('role')
        .eq('firebase_uid', user.uid)
        .maybeSingle();
        
    return response?['role'] as String?;
  } catch (e) {
    return null; 
  }
});