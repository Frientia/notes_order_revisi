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

  /// 1. Cek apakah petugas memiliki draft yang belum selesai, jika tidak ada, buat baru
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

      // Jika tidak ada draft aktif, buat baru di database
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

  /// 2. Ambil semua item detail belanja yang tersimpan di dalam draft aktif ini
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

  /// 3. Simpan item ke database saat petugas klik "Tambahkan ke Daftar" (Fase Rencana Beli)
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
      'status': 'PENDING', // Default awal di-set hutang/pending rencana
    });
  }

  /// 4. Hapus item dari database jika petugas membatalkan item tersebut di daftar
  Future<void> removeItemFromDraft(int idDetail) async {
    await _supabase.from('detail_pencatatan').delete().eq('id_detail_pencatatan', idDetail);
  }

  /// 5. Finalisasi Transaksi (Fase Eksekusi: Upload Kwitansi + Update Harga Riil + Set Status SELESAI)
  Future<void> finalisasiTransaksi({
    required int idPencatatan,
    required double grandTotal,
    required List<Map<String, dynamic>> finalItemsData, // Berisi id_detail, harga riil, status, biner kwitansi
  }) async {
    try {
      for (var item in finalItemsData) {
        final int idDetail = item['id_detail_pencatatan'];
        final Uint8List? imageBytes = item['image_bytes'];
        final String? imageName = item['image_name'];

        int? idKwitansi;

        // Hanya upload jika petugas melampirkan foto kwitansi saat eksekusi beli
        if (imageBytes != null && imageName != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final pathUpload = 'transaksi/${timestamp}_$imageName';
          
          await _supabase.storage.from('bukti_pembayaran').uploadBinary(pathUpload, imageBytes);
          final imgUrl = _supabase.storage.from('bukti_pembayaran').getPublicUrl(pathUpload);

          final kwitansiResp = await _supabase.from('kwitansi').insert({
            'img_url': imgUrl,
          }).select('id_kwitansi').single();
          
          idKwitansi = kwitansiResp['id_kwitansi'];
        }

        // Update baris detail dengan harga riil lapangan, status pembayaran riil, dan id_kwitansi
        await _supabase.from('detail_pencatatan').update({
          'harga_pembelian_barang': item['harga_pembelian_barang'],
          'status': item['status'], // 'SELESAI' (Lunas) atau 'PENDING' (Hutang)
          if (idKwitansi != null) 'id_kwitansi': idKwitansi,
        }).eq('id_detail_pencatatan', idDetail);
      }

      // Ubah status nota utama menjadi SELESAI dan simpan grand total akhir
      await _supabase.from('pencatatan').update({
        'total_harga': grandTotal,
        'status_transaksi': 'SELESAI',
        'tgl_pencatatan': DateTime.now().toIso8601String(), // Catat waktu asli eksekusi beli
      }).eq('id_pencatatan', idPencatatan);

     // ==========================================================
      // --- LOGIKA BARU: TEMBAK NOTIFIKASI KE HP BOSS ---
      // ==========================================================
      try {
        // 1. Cari token FCM milik Boss di tabel users
        // Pastikan kata 'eksekutif' di bawah ini cocok dengan role Boss di database Anda
        final responseToken = await _supabase
            .from('users')
            .select('fcm_token')
            .eq('role', 'boss') 
            .limit(1)
            .maybeSingle();

        // 2. Jika token Boss ketemu (artinya Boss sudah pernah login di HP-nya)
        if (responseToken != null && responseToken['fcm_token'] != null) {
          String fcmTokenBoss = responseToken['fcm_token'];

          // 3. Tarik pelatuk! Tembak notifikasi lewat Firebase
          await NotificationService.kirimNotifKeBoss(
            tokenBoss: fcmTokenBoss,
            title: '✅ Pencatatan Baru Selesai!',
            body: 'Petugas baru saja menyelesaikan input pengadaan sparepart. Ketuk untuk membuka dashboard.',
          );
        }
      } catch (e) {
        // Blok ini dibungkus try-catch agar jika notifikasi gagal (misal koneksi terputus tiba-tiba),
        // aplikasi Petugas tidak menjadi error dan data transaksi tetap aman tersimpan.
        print('Peringatan: Gagal mengirim notifikasi otomatis: $e');
      }
      // ==========================================================

    } catch (e) {
      throw Exception('Gagal memfinalisasi transaksi: $e');
    }
  }
}