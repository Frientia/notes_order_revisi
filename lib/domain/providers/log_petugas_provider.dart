import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Provider untuk menyimpan rentang tanggal kalender (Default: Hari ini)
final tanggalLogProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  // Default menampilkan data dari hari ini jam 00:00 s/d hari ini jam 23:59
  return DateTimeRange(
    start: DateTime(now.year, now.month, now.day),
    end: DateTime(now.year, now.month, now.day),
  );
});

class LogPetugasModel {
  final String namaPetugas;
  final String emailPetugas;
  final int jumlahInput;

  LogPetugasModel({
    required this.namaPetugas,
    required this.emailPetugas,
    required this.jumlahInput,
  });
}

// 2. Provider untuk mengambil data rekap petugas
final logPetugasListProvider = FutureProvider.autoDispose<List<LogPetugasModel>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final rentangTanggal = ref.watch(tanggalLogProvider); // Pantau kalender

  // Format tanggal mulai (Jam 00:00:00)
  final startIso = rentangTanggal.start.toIso8601String();
  // Format tanggal akhir (Kita setel ke jam 23:59:59 agar data di hari terakhir tetap masuk)
  final endDateTime = DateTime(
    rentangTanggal.end.year,
    rentangTanggal.end.month,
    rentangTanggal.end.day,
    23,
    59,
    59,
  );
  final endIso = endDateTime.toIso8601String();

  // Query dengan GTE (Lebih dari sama dengan Start) & LTE (Kurang dari sama dengan End)
  final response = await supabase
      .from('pencatatan')
      .select('firebase_uid, tgl_pencatatan, users (nama_user, email)')
      .eq('status_transaksi', 'SELESAI')
      .gte('tgl_pencatatan', startIso)
      .lte('tgl_pencatatan', endIso); // Batas akhir kalender

  final Map<String, Map<String, dynamic>> rekapMap = {};

  for (var row in response) {
    final uid = row['firebase_uid'] as String? ?? 'Unknown';
    final userMap = row['users'] as Map<String, dynamic>?;

    final namaAsli = userMap?['nama_user'] ?? 'Petugas Tidak Dikenal';
    final emailAsli = userMap?['email'] ?? 'Tidak ada email';

    if (rekapMap.containsKey(uid)) {
      rekapMap[uid]!['jumlah'] = (rekapMap[uid]!['jumlah'] as int) + 1;
    } else {
      rekapMap[uid] = {'nama': namaAsli, 'email': emailAsli, 'jumlah': 1};
    }
  }

  List<LogPetugasModel> listLog = [];
  rekapMap.forEach((uid, data) {
    listLog.add(
      LogPetugasModel(
        namaPetugas: data['nama'] as String,
        emailPetugas: data['email'] as String,
        jumlahInput: data['jumlah'] as int,
      ),
    );
  });

  listLog.sort((a, b) => b.jumlahInput.compareTo(a.jumlahInput));
  return listLog;
});
