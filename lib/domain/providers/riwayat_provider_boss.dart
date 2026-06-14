import 'package:flutter/material.dart'; // Diperlukan untuk mendefinisikan objek DateTimeRange
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Model Data Riwayat
class RiwayatTransaksi {
  final int idDetail;
  final int idNota;
  final DateTime tanggal;
  final String namaBarang;
  final String kategoriBarang;
  final String namaToko;
  final String nopolMobil;
  final String kategoriMobil;
  final String namaPetugas;
  final int qty;
  final double harga;
  final double subtotal;
  final String status;
  final String? imgKwitansi;

  RiwayatTransaksi({
    required this.idDetail,
    required this.idNota,
    required this.tanggal,
    required this.namaBarang,
    required this.kategoriBarang,
    required this.namaToko,
    required this.nopolMobil,
    required this.kategoriMobil,
    required this.namaPetugas,
    required this.qty,
    required this.harga,
    required this.subtotal,
    required this.status,
    this.imgKwitansi,
  });
}

// 2. Enum & State untuk Filter Kombinasi
enum FilterWaktu { semua, hariIni, mingguIni, bulanIni, pilihTanggal }

final filterWaktuRiwayatProvider = StateProvider.autoDispose<FilterWaktu>(
  (ref) => FilterWaktu.hariIni,
);
final searchRiwayatProvider = StateProvider.autoDispose<String>((ref) => '');

final filterTanggalCustomProvider = StateProvider<DateTimeRange?>((ref) => null);

final filterKategoriBarangProvider = StateProvider.autoDispose<String?>((ref) => null);
final filterKategoriMobilProvider = StateProvider.autoDispose<String?>((ref) => null);
final filterPetugasProvider = StateProvider.autoDispose<String?>((ref) => null);
final filterNamaBarangProvider = StateProvider.autoDispose<String?>((ref) => null);
final filterNoPlatProvider = StateProvider.autoDispose<String?>((ref) => null);

// 3. Provider Pengambil Data Riwayat (Repository & Future Terintegrasi)
final riwayatDataProvider = FutureProvider.autoDispose<List<RiwayatTransaksi>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('detail_pencatatan')
      .select('''
        id_detail_pencatatan,
        qty,
        harga_pembelian_barang,
        status,
        barang (nama_barang, kategori_barang(nama_kategori)),
        toko (nama_toko),
        mobil (no_plat, kategori_mobil(nama_kategori)),
        kwitansi (img_url),
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
    final tanggal = tglString != null ? DateTime.parse(tglString).toLocal() : DateTime.now();

    final qty = row['qty'] as int? ?? 0;
    final harga = (row['harga_pembelian_barang'] as num?)?.toDouble() ?? 0.0;

    listRiwayat.add(
      RiwayatTransaksi(
        idDetail: row['id_detail_pencatatan'] as int,
        idNota: pencatatan['id_pencatatan'] as int? ?? 0,
        tanggal: tanggal,
        namaBarang: row['barang']?['nama_barang'] ?? 'Barang Terhapus',
        kategoriBarang: row['barang']?['kategori_barang']?['nama_kategori'] ?? 'Tanpa Kategori',
        namaToko: row['toko']?['nama_toko'] ?? 'Tanpa Toko',
        nopolMobil: row['mobil']?['no_plat'] ?? '-',
        kategoriMobil: row['mobil']?['kategori_mobil']?['nama_kategori'] ?? 'Tanpa Kategori',
        namaPetugas: pencatatan['users']?['nama_user'] ?? 'Sistem',
        qty: qty,
        harga: harga,
        subtotal: qty * harga,
        status: row['status'] ?? 'PENDING',
        imgKwitansi: row['kwitansi']?['img_url'],
      ),
    );
  }
  return listRiwayat;
});

// 4. Provider Kombinasi Filter dengan Dukungan Seleksi Rentang Waktu
final riwayatFilteredProvider = Provider.autoDispose<AsyncValue<List<RiwayatTransaksi>>>((ref) {
  final rawState = ref.watch(riwayatDataProvider);

  final filterWaktu = ref.watch(filterWaktuRiwayatProvider);
  final customRange = ref.watch(filterTanggalCustomProvider); 
  final query = ref.watch(searchRiwayatProvider).toLowerCase();

  final filterKatBarang = ref.watch(filterKategoriBarangProvider);
  final filterKatMobil = ref.watch(filterKategoriMobilProvider);
  final filterPetugas = ref.watch(filterPetugasProvider);
  final filterNamaBarang = ref.watch(filterNamaBarangProvider);
  final filterNoPlat = ref.watch(filterNoPlatProvider);

  return rawState.whenData((list) {
    final now = DateTime.now();

    var filteredList = list.where((item) {
      // --- 1. FILTER WAKTU ---
      if (filterWaktu == FilterWaktu.hariIni) {
        if (item.tanggal.year != now.year || item.tanggal.month != now.month || item.tanggal.day != now.day) {
          return false;
        }
      } else if (filterWaktu == FilterWaktu.bulanIni) {
        if (item.tanggal.year != now.year || item.tanggal.month != now.month) {
          return false;
        }
      } else if (filterWaktu == FilterWaktu.mingguIni) {
        final difference = now.difference(item.tanggal).inDays;
        if (difference < 0 || difference > 7) return false;
      } 
      else if (filterWaktu == FilterWaktu.pilihTanggal && customRange != null) {
        final startBoundary = DateTime(customRange.start.year, customRange.start.month, customRange.start.day).subtract(const Duration(seconds: 1));
        final endBoundary = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59).add(const Duration(seconds: 1));
        
        if (!item.tanggal.isAfter(startBoundary) || !item.tanggal.isBefore(endBoundary)) {
          return false;
        }
      }

      // --- 2. FILTER LANJUTAN DROPDOWN ---
      if (filterKatBarang != null && item.kategoriBarang != filterKatBarang) return false;
      if (filterKatMobil != null && item.kategoriMobil != filterKatMobil) return false;
      if (filterPetugas != null && item.namaPetugas != filterPetugas) return false;
      if (filterNamaBarang != null && item.namaBarang != filterNamaBarang) return false;
      if (filterNoPlat != null && item.nopolMobil != filterNoPlat) return false;

      // --- 3. FILTER KEYWORD PENCARIAN ---
      if (query.isNotEmpty) {
        final match = item.namaBarang.toLowerCase().contains(query) ||
            item.namaToko.toLowerCase().contains(query) ||
            item.nopolMobil.toLowerCase().contains(query) ||
            item.namaPetugas.toLowerCase().contains(query);
        if (!match) return false;
      }

      return true;
    }).toList();

    return filteredList;
  });
});

// --- FITUR DASHBOARD: 5 PENCATATAN TERBARU HARI INI ---
final recentTransaksiDashboardProvider = FutureProvider.autoDispose<List<RiwayatTransaksi>>((ref) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();

  final response = await supabase
      .from('detail_pencatatan')
      .select('''
        id_detail_pencatatan,
        qty,
        harga_pembelian_barang,
        status,
        barang (nama_barang, kategori_barang(nama_kategori)),
        toko (nama_toko),
        mobil (no_plat, kategori_mobil(nama_kategori)),
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
  List<RiwayatTransaksi> listHariIni = [];
  
  final Set<int> trackedNotaIds = {};

  for (var row in rawData) {
    final pencatatan = row['pencatatan'];
    if (pencatatan == null) continue;

    final tglString = pencatatan['tgl_pencatatan'];
    final tanggal = tglString != null ? DateTime.parse(tglString).toLocal() : DateTime.now();

    if (tanggal.year == now.year && tanggal.month == now.month && tanggal.day == now.day) {
      final int idNota = pencatatan['id_pencatatan'] as int? ?? 0;
      
      if (trackedNotaIds.contains(idNota)) continue;

      final qty = row['qty'] as int? ?? 0;
      final harga = (row['harga_pembelian_barang'] as num?)?.toDouble() ?? 0.0;

      listHariIni.add(
        RiwayatTransaksi(
          idDetail: row['id_detail_pencatatan'] as int,
          idNota: idNota,
          tanggal: tanggal,
          namaBarang: row['barang']?['nama_barang'] ?? 'Barang Terhapus',
          kategoriBarang: row['barang']?['kategori_barang']?['nama_kategori'] ?? '-',
          namaToko: row['toko']?['nama_toko'] ?? '-',
          nopolMobil: row['mobil']?['no_plat'] ?? '-',
          kategoriMobil: row['mobil']?['kategori_mobil']?['nama_kategori'] ?? '-',
          namaPetugas: pencatatan['users']?['nama_user'] ?? 'Sistem',
          qty: qty,
          harga: harga,
          subtotal: qty * harga,
          status: row['status'] ?? 'PENDING',
        ),
      );

      trackedNotaIds.add(idNota);
    }

    if (listHariIni.length == 5) break;
  }

  return listHariIni;
});