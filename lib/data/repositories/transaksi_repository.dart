import 'dart:typed_data';
import 'package:notes_order/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transaksiRepositoryProvider = Provider<TransaksiRepository>((ref) {
  return TransaksiRepository(Supabase.instance.client);
});

class TransaksiRepository {
  final SupabaseClient _supabase;
  
  TransaksiRepository(this._supabase);

  Future<int> getOrCreateActiveDraft(String firebaseUid) async {
    try {
      final existing = await _supabase
          .from('pencatatan')
          .select('id_pencatatan')
          .eq('firebase_uid', firebaseUid)
          .eq('status_transaksi', 'DRAFT')
          .maybeSingle();

      if (existing != null) {
        return existing['id_pencatatan'] as int;
      }

      final newDraft = await _supabase.from('pencatatan').insert({
        'firebase_uid': firebaseUid,
        'total_harga': 0,
        'status_transaksi': 'DRAFT',
      }).select('id_pencatatan').single();

      return newDraft['id_pencatatan'] as int;
    } catch (e) {
      throw Exception('Gagal menginisialisasi Draft: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDraftItems(int idPencatatan) async {
    return await _supabase
        .from('detail_pencatatan')
        .select('''
          id_detail_pencatatan, id_barang, id_mobil, id_toko, qty, harga_pembelian_barang, status,
          barang (nama_barang, kategori),
          mobil (no_plat, kategori),
          toko (nama_toko)
        ''')
        .eq('id_pencatatan', idPencatatan);
  }

  Future<void> addItemToDraft({
    required int idPencatatan,
    required int idBarang,
    required int idMobil,
    required int idToko,
    required int qty,
    double hargaEstimasi = 0,
  }) async {
    await _supabase.from('detail_pencatatan').insert({
      'id_pencatatan': idPencatatan,
      'id_barang': idBarang,
      'id_mobil': idMobil,
      'id_toko': idToko,
      'qty': qty,
      'harga_pembelian_barang': hargaEstimasi,
      'status': 'PENDING',
    });
  }

  Future<void> removeItemFromDraft(int idDetail) async {
    await _supabase.from('detail_pencatatan').delete().eq('id_detail_pencatatan', idDetail);
  }

  Future<void> finalisasiTransaksi({
    required int idPencatatan,
    required double grandTotal,
    required List<Map<String, dynamic>> finalItemsData,
  }) async {
    try {
      final Map<int, int> uploadedKwitansiMap = {};

      for (var item in finalItemsData) {
        final int refId = item['kwitansi_ref_id'];

        if (item['image_bytes'] != null && !uploadedKwitansiMap.containsKey(refId)) {
          final Uint8List imageBytes = item['image_bytes'];
          final String imageName = item['image_name'];
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final pathUpload = 'transaksi/${timestamp}_$imageName';

          await _supabase.storage.from('bukti_pembayaran').uploadBinary(pathUpload, imageBytes);
          final imgUrl = _supabase.storage.from('bukti_pembayaran').getPublicUrl(pathUpload);

          final kwitansiResp = await _supabase.from('kwitansi').insert({
            'img_url': imgUrl,
          }).select('id_kwitansi').single();

          uploadedKwitansiMap[refId] = kwitansiResp['id_kwitansi'];
        }
      }

      for (var item in finalItemsData) {
        final int refId = item['kwitansi_ref_id'];
        
        if (uploadedKwitansiMap.containsKey(refId)) {
          final int realIdKwitansi = uploadedKwitansiMap[refId]!;

          await _supabase.from('detail_pencatatan').update({
            'harga_pembelian_barang': item['harga_pembelian_barang'],
            'status': item['status'],
            'id_kwitansi': realIdKwitansi,
          }).eq('id_detail_pencatatan', item['id_detail_pencatatan']);
        }
      }

      await _supabase.from('pencatatan').update({
        'total_harga': grandTotal,
        'status_transaksi': 'SELESAI',
        'tgl_pencatatan': DateTime.now().toIso8601String(),
      }).eq('id_pencatatan', idPencatatan);

      try {
        final responseToken = await _supabase
            .from('users')
            .select('fcm_token')
            .eq('role', 'boss')
            .limit(1)
            .maybeSingle();

        if (responseToken != null && responseToken['fcm_token'] != null) {
          final String fcmTokenBoss = responseToken['fcm_token'];

          await NotificationService.kirimNotifKeBoss(
            tokenBoss: fcmTokenBoss,
            title: '✅ Pencatatan Baru Selesai!',
            body: 'Petugas baru saja menyelesaikan input pengadaan sparepart. Ketuk untuk membuka dashboard.',
          );
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Gagal memfinalisasi transaksi: $e');
    }
  }
}