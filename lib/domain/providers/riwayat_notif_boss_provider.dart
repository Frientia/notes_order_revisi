import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final riwayatNotifBossProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('notifikasi')
      .stream(primaryKey: ['id_notif'])
      .order('created_at', ascending: false)
      .map((data) => List<Map<String, dynamic>>.from(data));
});