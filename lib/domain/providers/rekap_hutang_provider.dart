import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Model Data Riwayat
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
  final String status;

  _DetailHutangRaw({
    required this.idToko,
    required this.namaToko,
    required this.subtotal,
    required this.tglPencatatan,
    required this.status,
  });
}

enum SortirHutang { tertinggi, terendah, abjad }

final searchHutangProvider = StateProvider<String>((ref) => '');
final sortirHutangProvider = StateProvider<SortirHutang>((ref) => SortirHutang.tertinggi);

// --- PERBAIKAN 2: SET DEFAULT AWAL KE NULL AGAR MEMANTAU SEMUA BULAN SECARA UNIVERSAL ---
final bulanHutangProvider = StateProvider<DateTime?>((ref) => null);

// Ambil semua data transaksi dari database
final rekapHutangRawProvider = FutureProvider.autoDispose<List<_DetailHutangRaw>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('detail_pencatatan')
      .select('qty, harga_pembelian_barang, id_toko, status, toko(nama_toko), pencatatan!inner(status_transaksi, tgl_pencatatan)')
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
        tglPencatatan: DateTime.parse(pencatatan!['tgl_pencatatan']).toLocal(),
        status: row['status'] ?? 'PENDING',
      ),
    );
  }
  return listMentah;
});

// Memproses filter data untuk halaman utama rekap hutang
final rekapHutangFilteredProvider = Provider.autoDispose<AsyncValue<List<RekapHutangModel>>>((ref) {
  final rawState = ref.watch(rekapHutangRawProvider);
  final query = ref.watch(searchHutangProvider).toLowerCase();
  final sortir = ref.watch(sortirHutangProvider);
  final filterBulan = ref.watch(bulanHutangProvider);

  return rawState.whenData((rawList) {
    Iterable<_DetailHutangRaw> dataTersaring = rawList;
    if (filterBulan != null) {
      dataTersaring = rawList.where(
        (item) => item.tglPencatatan.year == filterBulan.year && item.tglPencatatan.month == filterBulan.month,
      );
    }

    final Map<int, RekapHutangModel> rekapMap = {};
    for (var item in dataTersaring) {
      final double hutangDitambahkan = item.status == 'PENDING' ? item.subtotal : 0.0;
      final int pendingDitambahkan = item.status == 'PENDING' ? 1 : 0;

      if (rekapMap.containsKey(item.idToko)) {
        final existing = rekapMap[item.idToko]!;
        rekapMap[item.idToko] = RekapHutangModel(
          idToko: item.idToko,
          namaToko: item.namaToko,
          totalHutang: existing.totalHutang + hutangDitambahkan,
          jumlahItemPending: existing.jumlahItemPending + pendingDitambahkan,
        );
      } else {
        rekapMap[item.idToko] = RekapHutangModel(
          idToko: item.idToko,
          namaToko: item.namaToko,
          totalHutang: hutangDitambahkan,
          jumlahItemPending: pendingDitambahkan,
        );
      }
    }

    List<RekapHutangModel> hasilAkhir = rekapMap.values.toList();
    if (query.isNotEmpty) {
      hasilAkhir = hasilAkhir.where((toko) => toko.namaToko.toLowerCase().contains(query)).toList();
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

class GrupNotaHutang {
  final int idNota;
  final DateTime tanggal;
  final DateTime? tglJatuhTempo; // <--- PERBAIKAN 3: Daftarkan tglJatuhTempo ke Model Utama
  final double totalHutangNota;
  final int jumlahMacamBarang;
  final List<Map<String, dynamic>> rincianBarang;

  GrupNotaHutang({
    required this.idNota,
    required this.tanggal,
    this.tglJatuhTempo,
    required this.totalHutangNota,
    required this.jumlahMacamBarang,
    required this.rincianBarang,
  });
}

// Mengelompokkan dengan mempertahankan histori barang (SINKRON DETAIL DATABASES NEW)
final detailHutangTokoProvider = FutureProvider.autoDispose.family<List<GrupNotaHutang>, int>((ref, idToko) async {
  final supabase = Supabase.instance.client;
  final filterBulan = ref.watch(bulanHutangProvider);

  final response = await supabase
      .from('detail_pencatatan')
      // --- UPDATE KUERI: Tarik kolom tgl_jatuh_tempo dari database ---
      .select('id_detail_pencatatan, qty, harga_pembelian_barang, status, tgl_jatuh_tempo, barang(nama_barang), pencatatan!inner(id_pencatatan, tgl_pencatatan)')
      .eq('pencatatan.status_transaksi', 'SELESAI')
      .eq('id_toko', idToko)
      .order('id_detail_pencatatan', ascending: false);

  final Map<int, GrupNotaHutang> groupedMap = {};

  for (var row in response) {
    final pencatatan = row['pencatatan'] as Map<String, dynamic>?;
    if (pencatatan == null) continue;

    final int idNota = pencatatan['id_pencatatan'] as int? ?? 0;
    final tglString = pencatatan['tgl_pencatatan'];
    final tanggal = tglString != null ? DateTime.parse(tglString).toLocal() : DateTime.now();

    // Mapping tanggal jatuh tempo dari baris detail_pencatatan database Boss
    final jatuhTempoStr = row['tgl_jatuh_tempo'];
    final DateTime? tglJatuhTempo = jatuhTempoStr != null ? DateTime.parse(jatuhTempoStr.toString()).toLocal() : null;

    if (filterBulan != null) {
      if (tanggal.year != filterBulan.year || tanggal.month != filterBulan.month) {
        continue; 
      }
    }

    final qty = row['qty'] as int;
    final harga = (row['harga_pembelian_barang'] as num).toDouble();
    final subtotal = qty * harga;
    final statusItem = row['status'] ?? 'PENDING';

    final dataBarang = row['barang'] as Map<String, dynamic>?;
    final namaBarang = dataBarang?['nama_barang'] ?? 'Barang Tanpa Nama';

    final rincianItem = {
      'id_detail_pencatatan': row['id_detail_pencatatan'] as int,
      'nama_barang': namaBarang,
      'qty': qty,
      'harga': harga,
      'subtotal': subtotal,
      'status': statusItem,
    };

    final double hutangNotaDitambahkan = statusItem == 'PENDING' ? subtotal : 0.0;

    if (groupedMap.containsKey(idNota)) {
      final existingGroup = groupedMap[idNota]!;
      existingGroup.rincianBarang.add(rincianItem);

      groupedMap[idNota] = GrupNotaHutang(
        idNota: idNota,
        tanggal: existingGroup.tanggal,
        tglJatuhTempo: existingGroup.tglJatuhTempo ?? tglJatuhTempo, // Jaga agar referensi tanggal tersimpan
        totalHutangNota: existingGroup.totalHutangNota + hutangNotaDitambahkan,
        jumlahMacamBarang: existingGroup.jumlahMacamBarang + 1,
        rincianBarang: existingGroup.rincianBarang,
      );
    } else {
      groupedMap[idNota] = GrupNotaHutang(
        idNota: idNota,
        tanggal: tanggal,
        tglJatuhTempo: tglJatuhTempo,
        totalHutangNota: max(0.0, hutangNotaDitambahkan),
        jumlahMacamBarang: 1,
        rincianBarang: [rincianItem],
      );
    }
  }

  final listGroup = groupedMap.values.toList();
  listGroup.sort((a, b) => b.idNota.compareTo(a.idNota));

  return listGroup;
});

final urlKwitansiProvider = FutureProvider.autoDispose.family<String?, int>((ref, idPencatatan) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('kwitansi')
      .select('img_url')
      .eq('id_kwitansi', idPencatatan)
      .maybeSingle();

  return response?['img_url'] as String?;
});

final aksiHutangProvider = Provider((ref) => AksiHutang(ref));

class AksiHutang {
  final Ref ref;
  AksiHutang(this.ref);

  // ─── PERBAIKAN 4: MASUKKAN METODE PELUNASAN TRANSFER KE DALAM KLAS AKSIHUTANG agar terdeteksi UI ───
  Future<void> lunaskanDenganBuktiTf({
    required int idToko,
    required DateTime periodeBulan,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final supabase = Supabase.instance.client;

    // 1. PERBAIKAN: Gunakan bucket 'invoice_tf' khusus arsip transfer Pimpinan
    final String pathFile = 'bukti_transfer/toko_$idToko\_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('invoice_tf').uploadBinary(pathFile, imageBytes);
    
    // 2. PERBAIKAN: Ambil URL publik dari bucket 'invoice_tf'
    final String publicUrl = supabase.storage.from('invoice_tf').getPublicUrl(pathFile);

    // 3. Masukkan data log rekaman ke tabel bukti_transfer
    await supabase.from('bukti_transfer').insert({
      'id_toko': idToko,
      'periode_bulan': periodeBulan.toIso8601String(),
      'img_url': publicUrl,
    });

    // 4. Update status seluruh detail_pencatatan toko tersebut menjadi SELESAI
    await supabase
        .from('detail_pencatatan')
        .update({
          'status': 'SELESAI',
          'tgl_pelunasan': DateTime.now().toIso8601String(),
        })
        .eq('id_toko', idToko)
        .eq('status', 'PENDING');

    // 5. Invalidation otomatis untuk memperbarui UI screen utama
    ref.invalidate(rekapHutangRawProvider);
    ref.invalidate(detailHutangTokoProvider(idToko));
  }

  Future<void> lunaskanSemuaBulanIni(int idToko, DateTime? filterBulan) async {
    final supabase = Supabase.instance.client;

    final selectQuery = supabase
        .from('detail_pencatatan')
        .select('id_detail_pencatatan, pencatatan!inner(tgl_pencatatan, status_transaksi)')
        .eq('id_toko', idToko)
        .eq('status', 'PENDING')
        .eq('pencatatan.status_transaksi', 'SELESAI');

    dynamic rawData;
    try {
      final legacyRes = await (selectQuery as dynamic).execute();
      rawData = legacyRes.data;
    } catch (_) {
      rawData = await selectQuery;
    }

    List<dynamic> listData = [];
    if (rawData is List) {
      listData = rawData;
    } else if (rawData != null && rawData is Map && rawData['data'] is List) {
      listData = rawData['data'] as List<dynamic>;
    }

    List<int> idsToUpdate = [];
    for (var item in listData) {
      if (item['pencatatan'] == null) continue;
      final tglString = item['pencatatan']['tgl_pencatatan'];
      if (tglString == null) continue;

      final tgl = DateTime.parse(tglString.toString()).toLocal();

      if (filterBulan != null) {
        if (tgl.year == filterBulan.year && tgl.month == filterBulan.month) {
          idsToUpdate.add(item['id_detail_pencatatan'] as int);
        }
      } else {
        if (item['id_detail_pencatatan'] != null) {
          idsToUpdate.add(item['id_detail_pencatatan'] as int);
        }
      }
    }

    if (idsToUpdate.isEmpty) {
      throw 'Tidak ada data tagihan yang sesuai untuk dilunasi.';
    }

    for (final id in idsToUpdate) {
      final updateQuery = supabase
          .from('detail_pencatatan')
          .update({'status': 'SELESAI', 'tgl_pelunasan': DateTime.now().toIso8601String()})
          .eq('id_detail_pencatatan', id);

      try {
        await (updateQuery as dynamic).execute();
      } catch (_) {
        await updateQuery;
      }
    }

    ref.invalidate(rekapHutangRawProvider);
    ref.invalidate(detailHutangTokoProvider(idToko));
  }
}
// Provider untuk mengambil foto bukti transfer dari tabel 'bukti_transfer'
final urlBuktiTransferProvider = FutureProvider.autoDispose.family<String?, int>((ref, idToko) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('bukti_transfer')
      .select('img_url')
      .eq('id_toko', idToko)
      // Ambil bukti transfer yang paling terbaru diupload
      .order('tgl_upload', ascending: false) 
      .maybeSingle();

  return response?['img_url'] as String?;
});