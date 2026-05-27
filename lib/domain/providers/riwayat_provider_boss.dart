import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Model Data Riwayat
class RiwayatTransaksi {
  final int idDetail;
  final int idNota;
  final DateTime tanggal;
  final String namaBarang;
  final String namaToko;
  final String nopolMobil;
  final String namaPetugas;
  final int qty;
  final double harga;
  final double subtotal;
  final String status;

  RiwayatTransaksi({
    required this.idDetail,
    required this.idNota,
    required this.tanggal,
    required this.namaBarang,
    required this.namaToko,
    required this.nopolMobil,
    required this.namaPetugas,
    required this.qty,
    required this.harga,
    required this.subtotal,
    required this.status,
  });
}

// 2. Enum & State untuk Filter
enum FilterWaktu { semua, hariIni, mingguIni, bulanIni }

final filterWaktuRiwayatProvider = StateProvider.autoDispose<FilterWaktu>(
  (ref) => FilterWaktu.bulanIni,
);
final searchRiwayatProvider = StateProvider.autoDispose<String>((ref) => '');

// 3. Provider Pengambil Data Riwayat
final riwayatDataProvider = FutureProvider.autoDispose<List<RiwayatTransaksi>>((
  ref,
) async {
  final supabase = Supabase.instance.client;

  // PERHATIAN:
  // Sesuaikan 'users(nama_user)' atau 'petugas(nama_petugas)' dengan tabel akun login petugas Anda.
  // Sesuaikan 'mobil(nopol)' dengan tabel mobil Anda.
  final response = await supabase
      .from('detail_pencatatan')
      .select('''
        id_detail_pencatatan,
        qty,
        harga_pembelian_barang,
        status,
        barang (nama_barang),
        toko (nama_toko),
        mobil (no_plat),
        pencatatan!inner (
          id_pencatatan,
          tgl_pencatatan,
          status_transaksi,
          users (nama_user)
        )
      ''')
      .eq('pencatatan.status_transaksi', 'SELESAI')
      .order('id_detail_pencatatan', ascending: false);

  final List<dynamic> rawData = response as List<dynamic>;
  List<RiwayatTransaksi> listRiwayat = [];

  for (var row in rawData) {
    final pencatatan = row['pencatatan'];
    if (pencatatan == null) continue;

    final tglString = pencatatan['tgl_pencatatan'];
    final tanggal = tglString != null
        ? DateTime.parse(tglString)
        : DateTime.now();

    final qty = row['qty'] as int? ?? 0;
    final harga = (row['harga_pembelian_barang'] as num?)?.toDouble() ?? 0.0;

    listRiwayat.add(
      RiwayatTransaksi(
        idDetail: row['id_detail_pencatatan'] as int,
        idNota: pencatatan['id_pencatatan'] as int? ?? 0,
        tanggal: tanggal,
        namaBarang: row['barang']?['nama_barang'] ?? 'Barang Terhapus/Kosong',
        namaToko: row['toko']?['nama_toko'] ?? 'Tanpa Toko',
        nopolMobil: row['mobil']?['no_plat'] ?? '-',
        namaPetugas: pencatatan['users']?['nama_user'] ?? 'Sistem',
        qty: qty,
        harga: harga,
        subtotal: qty * harga,
        status: row['status'] ?? 'PENDING',
      ),
    );
  }
  return listRiwayat;
});

// 4. Provider yang Memfilter Data (Search & Waktu)
final riwayatFilteredProvider =
    Provider.autoDispose<AsyncValue<List<RiwayatTransaksi>>>((ref) {
      final rawState = ref.watch(riwayatDataProvider);
      final filterWaktu = ref.watch(filterWaktuRiwayatProvider);
      final query = ref.watch(searchRiwayatProvider).toLowerCase();

      return rawState.whenData((list) {
        final now = DateTime.now();

        // Filter Waktu
        var filteredList = list.where((item) {
          if (filterWaktu == FilterWaktu.semua) return true;
          if (filterWaktu == FilterWaktu.hariIni) {
            return item.tanggal.year == now.year &&
                item.tanggal.month == now.month &&
                item.tanggal.day == now.day;
          }
          if (filterWaktu == FilterWaktu.bulanIni) {
            return item.tanggal.year == now.year &&
                item.tanggal.month == now.month;
          }
          if (filterWaktu == FilterWaktu.mingguIni) {
            // Logika sederhana minggu ini (selisih max 7 hari ke belakang)
            final difference = now.difference(item.tanggal).inDays;
            return difference >= 0 && difference <= 7;
          }
          return true;
        }).toList();

        // Filter Pencarian (Cari berdasarkan Barang, Toko, Mobil, atau Petugas)
        if (query.isNotEmpty) {
          filteredList = filteredList.where((item) {
            return item.namaBarang.toLowerCase().contains(query) ||
                item.namaToko.toLowerCase().contains(query) ||
                item.nopolMobil.toLowerCase().contains(query) ||
                item.namaPetugas.toLowerCase().contains(query);
          }).toList();
        }

        return filteredList;
      });
    });
