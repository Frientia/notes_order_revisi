import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RekapHutangModel {
  final int idToko;
  final String namaToko;
  final double totalHutang;
  final int jumlahItemPending;

  RekapHutangModel({
    required this.idToko,
    required this.namaToko,
    required this.totalHutang,
    required this.jumlahItemPending,
  });
}

class _DetailHutangRaw {
  final int idToko;
  final String namaToko;
  final double subtotal;
  final DateTime tglPencatatan;

  _DetailHutangRaw({
    required this.idToko,
    required this.namaToko,
    required this.subtotal,
    required this.tglPencatatan,
  });
}

enum SortirHutang { tertinggi, terendah, abjad }

final searchHutangProvider = StateProvider<String>((ref) => '');
final sortirHutangProvider = StateProvider<SortirHutang>(
  (ref) => SortirHutang.tertinggi,
);
final bulanHutangProvider = StateProvider<DateTime?>((ref) => null);

// --- 1. PROVIDER DATA MENTAH UTAMA ---
final rekapHutangRawProvider = FutureProvider.autoDispose<List<_DetailHutangRaw>>((
  ref,
) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('detail_pencatatan')
      .select(
        'qty, harga_pembelian_barang, id_toko, toko(nama_toko), pencatatan!inner(status_transaksi, tgl_pencatatan)',
      )
      .eq('status', 'PENDING')
      .eq('pencatatan.status_transaksi', 'SELESAI');

  List<_DetailHutangRaw> listMentah = [];
  for (var row in response) {
    final pencatatan = row['pencatatan'] as Map<String, dynamic>?;
    if (pencatatan?['tgl_pencatatan'] == null) continue;

    final qty = row['qty'] as int;
    final harga = (row['harga_pembelian_barang'] as num).toDouble();

    listMentah.add(
      _DetailHutangRaw(
        idToko: row['id_toko'] as int,
        namaToko: row['toko']?['nama_toko'] ?? 'Toko Tidak Diketahui',
        subtotal: qty * harga,
        tglPencatatan: DateTime.parse(pencatatan!['tgl_pencatatan']),
      ),
    );
  }
  return listMentah;
});

// --- 2. PROVIDER FILTER GABUNGAN ---
final rekapHutangFilteredProvider =
    Provider.autoDispose<AsyncValue<List<RekapHutangModel>>>((ref) {
      final rawState = ref.watch(rekapHutangRawProvider);
      final query = ref.watch(searchHutangProvider).toLowerCase();
      final sortir = ref.watch(sortirHutangProvider);
      final filterBulan = ref.watch(bulanHutangProvider);

      return rawState.whenData((rawList) {
        Iterable<_DetailHutangRaw> dataTersaring = rawList;
        if (filterBulan != null) {
          dataTersaring = rawList.where(
            (item) =>
                item.tglPencatatan.year == filterBulan.year &&
                item.tglPencatatan.month == filterBulan.month,
          );
        }

        final Map<int, RekapHutangModel> rekapMap = {};
        for (var item in dataTersaring) {
          if (rekapMap.containsKey(item.idToko)) {
            final existing = rekapMap[item.idToko]!;
            rekapMap[item.idToko] = RekapHutangModel(
              idToko: item.idToko,
              namaToko: item.namaToko,
              totalHutang: existing.totalHutang + item.subtotal,
              jumlahItemPending: existing.jumlahItemPending + 1,
            );
          } else {
            rekapMap[item.idToko] = RekapHutangModel(
              idToko: item.idToko,
              namaToko: item.namaToko,
              totalHutang: item.subtotal,
              jumlahItemPending: 1,
            );
          }
        }

        List<RekapHutangModel> hasilAkhir = rekapMap.values.toList();
        if (query.isNotEmpty) {
          hasilAkhir = hasilAkhir
              .where((toko) => toko.namaToko.toLowerCase().contains(query))
              .toList();
        }

        switch (sortir) {
          case SortirHutang.tertinggi:
            hasilAkhir.sort((a, b) => b.totalHutang.compareTo(a.totalHutang));
            break;
          case SortirHutang.terendah:
            hasilAkhir.sort((a, b) => a.totalHutang.compareTo(b.totalHutang));
            break;
          case SortirHutang.abjad:
            hasilAkhir.sort((a, b) => a.namaToko.compareTo(b.namaToko));
            break;
        }
        return hasilAkhir;
      });
    });

// --- 3. PROVIDER BARU: UNTUK MENGAMBIL RINCIAN NOTA PER TOKO ---
final detailHutangTokoProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, idToko) async {
      final supabase = Supabase.instance.client;

      // Ambil detail pencatatan yang PENDING di toko spesifik tersebut
      final response = await supabase
          .from('detail_pencatatan')
          .select(
            'qty, harga_pembelian_barang, pencatatan!inner(id_pencatatan, tgl_pencatatan)',
          )
          .eq('status', 'PENDING')
          .eq('pencatatan.status_transaksi', 'SELESAI')
          .eq('id_toko', idToko)
          .order('id_detail_pencatatan', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    });
