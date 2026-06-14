import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/riwayat_model.dart';

final riwayatRepositoryProvider = Provider<RiwayatRepository>((ref) {
  return RiwayatRepository(Supabase.instance.client);
});

class RiwayatRepository {
  final SupabaseClient _supabase;
  RiwayatRepository(this._supabase);

  Future<List<PencatatanModel>> getRiwayat({DateTime? startDate, DateTime? endDate}) async {
    // KITA UBAH SELECT-NYA UNTUK MELAKUKAN JOIN KE TABEL DETAIL
    var query = _supabase
        .from('pencatatan')
        .select('''
          *,
          detail_pencatatan (
            id_detail_pencatatan, qty, harga_pembelian_barang, subtotal, status,
            barang (nama_barang),
            mobil (no_plat),
            toko (nama_toko)
          )
        ''')
        .eq('status_transaksi', 'SELESAI'); 

    if (startDate != null && endDate != null) {
      query = query
          .gte('tgl_pencatatan', startDate.toUtc().toIso8601String())
          .lte('tgl_pencatatan', endDate.toUtc().toIso8601String());
    }

    final response = await query.order('tgl_pencatatan', ascending: false);
    
    return response.map((e) => PencatatanModel.fromJson(e)).toList();
  }

  Future<List<DetailPencatatanModel>> getDetailRiwayat(int idPencatatan) async {
    final response = await _supabase
        .from('detail_pencatatan')
        .select('''
          id_detail_pencatatan, 
          qty, 
          harga_pembelian_barang, 
          subtotal, 
          status, 
          tgl_jatuh_tempo, 
          tgl_pelunasan,
          barang (
            nama_barang, 
            kategori_barang (nama_kategori)
          ),
          mobil (no_plat),
          toko (nama_toko),
          kwitansi (img_url) 
        ''')
        .eq('id_pencatatan', idPencatatan)
        .order('id_detail_pencatatan', ascending: true);

    return response.map((e) => DetailPencatatanModel.fromJson(e)).toList();
  }
}

final riwayatListProvider = FutureProvider.autoDispose<List<PencatatanModel>>((ref) async {
  return ref.watch(riwayatRepositoryProvider).getRiwayat();
});

final detailRiwayatProvider = FutureProvider.family.autoDispose<List<DetailPencatatanModel>, int>((ref, idPencatatan) async {
  return ref.watch(riwayatRepositoryProvider).getDetailRiwayat(idPencatatan);
});