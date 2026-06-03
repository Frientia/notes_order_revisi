import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider untuk mengelola daftar ID transaksi yang sudah dibaca
final readNotificationsProvider = StateNotifierProvider<ReadNotificationsNotifier, List<int>>((ref) {
  return ReadNotificationsNotifier();
});

class ReadNotificationsNotifier extends StateNotifier<List<int>> {
  ReadNotificationsNotifier() : super([]) {
    _loadReadNotifs();
  }

  // Tarik data memori HP saat aplikasi baru dibuka
  Future<void> _loadReadNotifs() async {
    final prefs = await SharedPreferences.getInstance();
    final listString = prefs.getStringList('read_notifs') ?? [];
    // Ubah kembali dari String ke Integer
    state = listString.map((e) => int.parse(e)).toList();
  }

  // Fungsi untuk menandai notifikasi sudah dibaca
  Future<void> markAsRead(int id) async {
    if (!state.contains(id)) {
      final newState = [...state, id];
      state = newState; // Update tampilan UI
      
      // Simpan permanen ke memori HP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_notifs', newState.map((e) => e.toString()).toList());
    }
  }
}