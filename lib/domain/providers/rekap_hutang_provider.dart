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

// --- CLASS BARU UNTUK MENAMPUNG KELOMPOK NOTA ---
class GrupNotaHutang {
  final int idNota;
  final DateTime tanggal;
  final double totalHutangNota;
  final int jumlahMacamBarang;
  final List<Map<String, dynamic>> rincianBarang;

  GrupNotaHutang({
    required this.idNota,
    required this.tanggal,
    required this.totalHutangNota,
    required this.jumlahMacamBarang,
    required this.rincianBarang,
  });
}

// --- UPDATE: MENGELOMPOKKAN BARANG BERDASARKAN ID NOTA ---
final detailHutangTokoProvider = FutureProvider.autoDispose
    .family<List<GrupNotaHutang>, int>((ref, idToko) async {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('detail_pencatatan')
          .select(
            'qty, harga_pembelian_barang, barang(nama_barang), pencatatan!inner(id_pencatatan, tgl_pencatatan)',
          )
          .eq('status', 'PENDING')
          .eq('pencatatan.status_transaksi', 'SELESAI')
          .eq('id_toko', idToko)
          .order('id_detail_pencatatan', ascending: false);

      // Map untuk mengelompokkan berdasarkan id_pencatatan (ID Nota)
      final Map<int, GrupNotaHutang> groupedMap = {};

      for (var row in response) {
        final pencatatan = row['pencatatan'] as Map<String, dynamic>?;
        if (pencatatan == null) continue;

        final idNota = pencatatan['id_pencatatan'] as int? ?? 0;
        final tglString = pencatatan['tgl_pencatatan'];
        final tanggal = tglString != null
            ? DateTime.parse(tglString)
            : DateTime.now();

        final qty = row['qty'] as int;
        final harga = (row['harga_pembelian_barang'] as num).toDouble();
        final subtotal = qty * harga;

        final dataBarang = row['barang'] as Map<String, dynamic>?;
        final namaBarang = dataBarang?['nama_barang'] ?? 'Barang Tanpa Nama';

        // Bungkus rincian 1 barang
        final rincianItem = {
          'nama_barang': namaBarang,
          'qty': qty,
          'harga': harga,
          'subtotal': subtotal,
        };

        if (groupedMap.containsKey(idNota)) {
          // Jika Nota sudah ada, tambahkan barang ini ke dalamnya
          final existingGroup = groupedMap[idNota]!;
          existingGroup.rincianBarang.add(rincianItem);

          groupedMap[idNota] = GrupNotaHutang(
            idNota: idNota,
            tanggal: existingGroup.tanggal,
            totalHutangNota: existingGroup.totalHutangNota + subtotal,
            jumlahMacamBarang: existingGroup.jumlahMacamBarang + 1,
            rincianBarang: existingGroup.rincianBarang,
          );
        } else {
          // Jika Nota baru muncul, buat grup baru
          groupedMap[idNota] = GrupNotaHutang(
            idNota: idNota,
            tanggal: tanggal,
            totalHutangNota: subtotal,
            jumlahMacamBarang: 1,
            rincianBarang: [rincianItem],
          );
        }
      }

      // Ubah ke List dan urutkan dari Nota terbaru
      final listGroup = groupedMap.values.toList();
      listGroup.sort((a, b) => b.idNota.compareTo(a.idNota));

      return listGroup;
    });

// --- BARU: PROVIDER UNTUK MENGAMBIL GAMBAR KWITANSI ---
final urlKwitansiProvider = FutureProvider.autoDispose.family<String?, int>((
  ref,
  idPencatatan,
) async {
  final supabase = Supabase.instance.client;

  // Asumsi: id_kwitansi nilainya sama dengan id_pencatatan, atau ada relasi langsung.
  // Jika kolom fk-nya berbeda (misal 'id_pencatatan' ada di tabel kwitansi), ganti 'id_kwitansi' dengan kolom tersebut.
  final response = await supabase
      .from('kwitansi')
      .select('img_url')
      .eq('id_kwitansi', idPencatatan)
      .maybeSingle();

  return response?['img_url'] as String?;
});
