import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final riwayatNotifBossProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;

  // 1. DENGARKAN ALIRAN STREAM REAL-TIME DARI TABEL NOTIFIKASI UTAMA
  return supabase
      .from('notifikasi')
      .stream(primaryKey: ['id_notif'])
      .order('created_at', ascending: false)
      // Gunakan asyncMap agar kita bisa menembak kueri cek hutang secara asinkron di dalam stream
      .asyncMap((listNotifMentah) async {
        
        final List<Map<String, dynamic>> listNotifRealtime = 
            List<Map<String, dynamic>>.from(listNotifMentah);

        try {
          // 2. AMBIL DATA JATUH TEMPO DARI DETAIL PENCATATAN YANG MASIH PENDING
          final responseHutang = await supabase
              .from('detail_pencatatan')
              .select('id_detail_pencatatan, id_pencatatan, tgl_jatuh_tempo, status, toko(nama_toko)')
              .eq('status', 'PENDING');

          final Map<String, Map<String, dynamic>> reminderTokoMap = {};
          final skrg = DateTime.now();
          final hariIniBebasJam = DateTime(skrg.year, skrg.month, skrg.day);

          for (var row in responseHutang) {
            if (row['tgl_jatuh_tempo'] == null) continue;

            final tglTempo = DateTime.parse(row['tgl_jatuh_tempo'].toString());
            final tglTempoBebasJam = DateTime(tglTempo.year, tglTempo.month, tglTempo.day);

            // Hitung selisih hari menuju batas akhir tempo
            final sisaHari = tglTempoBebasJam.difference(hariIniBebasJam).inDays;
            final dataToko = row['toko'] as Map<String, dynamic>?;
            final namaToko = dataToko?['nama_toko'] ?? 'Toko Tidak Diketahui';

            // JIKA MEMASUKI H-3 HINGGA HARI-H (DAN SETERUSNYA SELAMA BELUM LUNAS)
            if (sisaHari <= 3) {
              String pesanWaktu = sisaHari == 0
                  ? 'HARI INI JATUH TEMPO!'
                  : (sisaHari < 0 ? 'TELAH LEWAT ${sisaHari.abs()} HARI!' : '$sisaHari Hari Lagi Jatuh Tempo');

              // Mengunci key berdasarkan namaToko agar notifikasi rapi disortir per toko, bukan per item barang
              reminderTokoMap[namaToko] = {
                'id_notif': -(row['id_detail_pencatatan'] as int), // ID negatif sebagai flag penanda notif sistem virtual
                'id_pencatatan': row['id_pencatatan'],
                'tipe_notif': 'REMINDER_HUTANG',
                'judul': 'Peringatan Jatuh Tempo: $namaToko',
                'pesan': 'Tagihan berjalan pada $namaToko sudah memasuki batas kritis pelunasan. Status: $pesanWaktu. Segera lakukan transfer dana dan upload bukti invoice untuk menutup transaksi.',
                'is_read': false, // Selalu false agar Boss tetap waspada di kotak masuk selama hutang belum dibayar
                'created_at': DateTime.now().toIso8601String(),
              };
            }
          }

          // 3. GABUNGKAN NOTIFIKASI AUTO-REMINDER TOKO DI ATAS DENGAN DAFTAR STREAM REAL-TIME PETUGAS
          return [...reminderTokoMap.values, ...listNotifRealtime];

        } catch (e) {
          // Jika kueri tabel detail_pencatatan gagal/gagal koneksi, kembalikan data notifikasi standar agar aplikasi tidak crash
          return listNotifRealtime;
        }
      });
});