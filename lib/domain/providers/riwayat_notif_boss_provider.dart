import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider ini akan memantau tabel 'pencatatan' secara Realtime
final riwayatNotifBossProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('pencatatan')
      .stream(primaryKey: ['id_pencatatan'])
      .eq('status_transaksi', 'SELESAI') // Hanya ambil yang sudah selesai
      .order('tgl_pencatatan', ascending: false) // Urutkan dari yang paling baru
      .map((data) => List<Map<String, dynamic>>.from(data));
});