import 'package:notes_order/data/models/keranjang_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transaksiRepositoryProvider = Provider<TransaksiRepository>((ref) {
  return TransaksiRepository(Supabase.instance.client);
});

class TransaksiRepository {
  final SupabaseClient _supabase;

  TransaksiRepository(this._supabase);

  Future<void> simpanTransaksiMultitoko({
    required String firebaseUid,
    required List<KeranjangItem> keranjang,
    required double grandTotal,
  }) async {
    try {
      final pencatatanResponse = await _supabase.from('pencatatan').insert({
        'total_harga': grandTotal,
        'firebase_uid': firebaseUid,
      }).select('id_pencatatan').single();
      
      final int idPencatatan = pencatatanResponse['id_pencatatan'];

      for (var item in keranjang) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final pathUpload = 'transaksi/${timestamp}_${item.imageName}';
        
        await _supabase.storage.from('bukti_pembayaran').uploadBinary(pathUpload, item.imageBytes);
        final imgUrl = _supabase.storage.from('bukti_pembayaran').getPublicUrl(pathUpload);

        final kwitansiResponse = await _supabase.from('kwitansi').insert({
          'img_url': imgUrl,
        }).select('id_kwitansi').single();
        
        final int idKwitansi = kwitansiResponse['id_kwitansi'];

        await _supabase.from('detail_pencatatan').insert({
          'id_pencatatan': idPencatatan,
          'id_barang': int.parse(item.idBarang),
          'id_mobil': int.parse(item.idMobil),
          'id_toko': int.parse(item.idToko),
          'id_kwitansi': idKwitansi,
          'qty': item.qty,
          'harga_pembelian_barang': item.hargaPembelian,
          'status': item.statusPembayaran,
        });
      }
    } catch (e) {
      throw Exception('Gagal memproses transaksi multi-toko: $e');
    }
  }
}