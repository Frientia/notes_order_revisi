import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Menggunakan Absolute Import agar tidak pernah error lokasi file
import 'package:notes_order/domain/providers/riwayat_provider_boss.dart';

final cetakTanggalMulaiProvider = StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final cetakTanggalSelesaiProvider = StateProvider.autoDispose<DateTime>(
  (ref) => DateTime.now(),
);
final cetakFilterStatusProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final cetakFilterNoPlatProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final cetakFilterKategoriBarangProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

final cetakRawDataProvider = FutureProvider.autoDispose<List<RiwayatTransaksi>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final tglMulai = ref.watch(cetakTanggalMulaiProvider);
  final tglSelesai = ref.watch(cetakTanggalSelesaiProvider);

  final startStr =
      "${tglMulai.year}-${tglMulai.month.toString().padLeft(2, '0')}-${tglMulai.day.toString().padLeft(2, '0')}T00:00:00";
  final endStr =
      "${tglSelesai.year}-${tglSelesai.month.toString().padLeft(2, '0')}-${tglSelesai.day.toString().padLeft(2, '0')}T23:59:59";

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
      .gte('pencatatan.tgl_pencatatan', startStr)
      .lte('pencatatan.tgl_pencatatan', endStr)
      .order('id_detail_pencatatan', ascending: true);

  final List<dynamic> rawData = response as List<dynamic>;
  List<RiwayatTransaksi> listData = [];

  for (var row in rawData) {
    final pencatatan = row['pencatatan'];
    if (pencatatan == null) continue;

    final qty = row['qty'] as int? ?? 0;
    final harga = (row['harga_pembelian_barang'] as num?)?.toDouble() ?? 0.0;

    listData.add(
      RiwayatTransaksi(
        idDetail: row['id_detail_pencatatan'] as int,
        idNota: pencatatan['id_pencatatan'] as int? ?? 0,
        tanggal: DateTime.parse(pencatatan['tgl_pencatatan']),
        namaBarang: row['barang']?['nama_barang'] ?? 'Barang Terhapus',
        // PERBAIKAN: Mapping data kategori dari relasi baru
        kategoriBarang: row['barang']?['kategori_barang']?['nama_kategori'] ?? '-',
        namaToko: row['toko']?['nama_toko'] ?? '-',
        nopolMobil: row['mobil']?['no_plat'] ?? '-',
        // PERBAIKAN: Mapping data kategori dari relasi baru
        kategoriMobil: row['mobil']?['kategori_mobil']?['nama_kategori'] ?? '-',
        namaPetugas: pencatatan['users']?['nama_user'] ?? 'Sistem',
        qty: qty,
        harga: harga,
        subtotal: qty * harga,
        status: row['status'] ?? 'PENDING',
        // PERBAIKAN: Menambahkan kwitansi agar sesuai dengan model RiwayatTransaksi terbaru
        imgKwitansi: row['kwitansi']?['img_url'], 
      ),
    );
  }
  return listData;
});

final cetakFilteredDataProvider = Provider.autoDispose<List<RiwayatTransaksi>>((
  ref,
) {
  final rawState = ref.watch(cetakRawDataProvider).value ?? [];
  final status = ref.watch(cetakFilterStatusProvider);
  final noPlat = ref.watch(cetakFilterNoPlatProvider);
  final katBarang = ref.watch(cetakFilterKategoriBarangProvider);

  return rawState.where((item) {
    if (status != null && item.status != status) return false;
    if (noPlat != null && item.nopolMobil != noPlat) return false;
    if (katBarang != null && item.kategoriBarang != katBarang) return false;
    return true;
  }).toList();
});