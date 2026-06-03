import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_order/domain/providers/rekap_hutang_provider.dart';

import '../../domain/providers/riwayat_notif_boss_provider.dart';
import '../../domain/providers/read_notif_provider.dart';
import '../../core/utils/formatters.dart';

// --- IMPORT PENTING UNTUK POP-UP & PENCARIAN DATA ASLI ---
import '../../domain/providers/riwayat_provider_boss.dart'; // Pastikan path ini benar sesuai proyek Anda

class RiwayatNotifScreen extends ConsumerWidget {
  const RiwayatNotifScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listNotifAsync = ref.watch(riwayatNotifBossProvider);
    final readNotifs = ref.watch(readNotificationsProvider);
    
    // Kita pantau juga data riwayat asli untuk dicocokkan dengan ID saat notif diklik
    final allRiwayatState = ref.watch(riwayatDataProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kotak Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: listNotifAsync.when(
        data: (listData) {
          if (listData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi masuk', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: listData.length,
            itemBuilder: (context, index) {
              final data = listData[index];
              final int idTransaksi = data['id_pencatatan'];
              final bool isRead = readNotifs.contains(idTransaksi);
              
              DateTime tgl = DateTime.now();
              if (data['tgl_pencatatan'] != null) {
                tgl = DateTime.parse(data['tgl_pencatatan']).toLocal();
              }
              final String totalRupiah = AppFormatters.rupiah(data['total_harga'] ?? 0);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isRead ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isRead ? [] : [
                    BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: isRead ? Colors.grey.shade300 : Colors.blue.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[300] : Colors.blue[50],
                    radius: 24,
                    child: Icon(
                      isRead ? Icons.drafts : Icons.mark_email_unread, 
                      color: isRead ? Colors.grey[600] : Colors.blue[600], size: 24
                    ),
                  ),
                  title: Text(
                    '✅ Pencatatan Selesai!',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15,
                      color: isRead ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Petugas telah menyelesaikan input pengadaan sparepart senilai $totalRupiah.',
                          style: TextStyle(fontSize: 13, color: isRead ? Colors.grey[500] : Colors.grey[800], height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: isRead ? Colors.grey[400] : Colors.blueGrey[400]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(tgl),
                              style: TextStyle(
                                fontSize: 12, color: isRead ? Colors.grey[400] : Colors.blueGrey[600],
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // 1. Tandai notifikasi menjadi abu-abu (dibaca)
                    ref.read(readNotificationsProvider.notifier).markAsRead(idTransaksi);
                    
                    // 2. Ambil list data riwayat dari State
                    final listSemuaRiwayat = allRiwayatState.value ?? [];
                    
                    try {
                      // 3. Cari objek RiwayatTransaksi yang ID-nya cocok dengan ID Notifikasi ini
                      final itemAsli = listSemuaRiwayat.firstWhere(
                        (item) => item.idNota == idTransaksi,
                      );
                      
                      // 4. Jika ketemu, luncurkan Pop-Up persis seperti di Riwayat Boss!
                      _showKwitansiDialog(context, ref, itemAsli);
                    } catch (e) {
                      // Jika data belum tersinkronisasi, tampilkan pesan error yang rapi
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Memuat detail... Silakan coba lagi atau cek menu Riwayat Keseluruhan.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Terjadi kesalahan: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  // =========================================================================
  // --- KUMPULAN WIDGET UNTUK MEMUNCULKAN POP-UP DETAIL KWITANSI ---
  // =========================================================================
  
  void _showKwitansiDialog(BuildContext context, WidgetRef ref, RiwayatTransaksi item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 24),

                  _detailRow('ID Nota / Detail:', '#${item.idNota} / #${item.idDetail}'),
                  _detailRow('Tanggal:', DateFormat('dd MMM yyyy, HH:mm').format(item.tanggal)),
                  _detailRow('Barang:', '${item.namaBarang} (${item.kategoriBarang})', isBold: true),
                  _detailRow('Toko:', item.namaToko),
                  _detailRow('Mobil:', '${item.nopolMobil} (${item.kategoriMobil})'),
                  _detailRow('Petugas:', item.namaPetugas),
                  _detailRow(
                    'Status:',
                    item.status == 'PENDING' ? 'HUTANG' : 'LUNAS',
                    color: item.status == 'PENDING' ? Colors.orange : Colors.green,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        AppFormatters.rupiah(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Bukti Kwitansi:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  
                  // Bagian memuat Foto Kwitansi
                  Consumer(
                    builder: (context, ref, child) {
                      final urlState = ref.watch(urlKwitansiProvider(item.idNota));

                      return urlState.when(
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())),
                        error: (err, stack) => const Center(child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.red))),
                        data: (url) {
                          if (url == null || url.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                              child: const Column(
                                children: [
                                  Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text('Petugas tidak mengupload foto kwitansi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[900],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold || color != null ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}