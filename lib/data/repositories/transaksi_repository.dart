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

      // === PERBAIKAN DI SINI: Tambahkan tgl_pencatatan ===
      final newDraft = await _supabase.from('pencatatan').insert({
        'firebase_uid': firebaseUid,
        'total_harga': 0,
        'status_transaksi': 'DRAFT',
        'tgl_pencatatan': DateTime.now().toIso8601String(), // Supabase biasanya butuh ini!
      }).select('id_pencatatan').single();

      return newDraft['id_pencatatan'] as int;
    } catch (e) {
      throw Exception('Gagal menginisialisasi Draft: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDraftItems(int idPencatatan) async {
    // REVISI: Menggunakan Deep Join ke tabel kategori_barang dan kategori_mobil
    final rawData = await _supabase
        .from('detail_pencatatan')
        .select('''
          id_detail_pencatatan, id_barang, id_mobil, id_toko, qty, harga_pembelian_barang, status, tgl_jatuh_tempo,
          barang (nama_barang, kategori_barang (nama_kategori)),
          mobil (no_plat, kategori_mobil (nama_kategori)),
          toko (nama_toko)
        ''')
        .eq('id_pencatatan', idPencatatan)
        .order('id_detail_pencatatan', ascending: true);

    // Mapping ulang agar UI FormPencatatan tetap bisa membaca 'kategori' dengan mudah
    return rawData.map((item) {
      final b = item['barang'] as Map<String, dynamic>?;
      if (b != null) {
        b['kategori'] = b['kategori_barang']?['nama_kategori'];
      }
      final m = item['mobil'] as Map<String, dynamic>?;
      if (m != null) {
        m['kategori'] = m['kategori_mobil']?['nama_kategori'];
      }
      return item;
    }).toList();
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

  // =======================================================================
  // FUNGSI BARU: Update Qty Item Draft (Dipanggil dari Form Pencatatan)
  // =======================================================================
  Future<void> updateQtyItemDraft(int idDetail, int newQty) async {
    await _supabase
        .from('detail_pencatatan')
        .update({'qty': newQty})
        .eq('id_detail_pencatatan', idDetail);
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
            if (item['tgl_jatuh_tempo'] != null) 'tgl_jatuh_tempo': item['tgl_jatuh_tempo'],
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