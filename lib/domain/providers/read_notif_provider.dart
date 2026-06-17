import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final readNotificationsProvider = Provider<ReadNotifService>((ref) {
  return ReadNotifService(Supabase.instance.client);
});

class ReadNotifService {
  final SupabaseClient _supabase;

  ReadNotifService(this._supabase);

  Future<void> markAsRead(int idNotif) async {
    try {
      await _supabase
          .from('notifikasi')
          .update({'is_read': true})
          .eq('id_notif', idNotif);
    } catch (e) {
      print('Gagal update status baca: $e');
    }
  }

  Future<void> markAllAsRead(List<int> allIds) async {
    if (allIds.isEmpty) return;
    
    try {
      await _supabase
          .from('notifikasi')
          .update({'is_read': true})
          .inFilter('id_notif', allIds);
    } catch (e) {
      print('Gagal update semua status baca: $e');
    }
  }
}