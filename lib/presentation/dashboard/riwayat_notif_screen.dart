import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// PENTING: Sesuaikan kedua path import di bawah ini dengan struktur folder proyek Anda
import '../../domain/providers/riwayat_notif_boss_provider.dart'; 
import '../../core/utils/formatters.dart'; // Asumsi Anda punya AppFormatters.rupiah()

class RiwayatNotifScreen extends ConsumerWidget {
  const RiwayatNotifScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau aliran data dari database Supabase secara Realtime
    final listNotifAsync = ref.watch(riwayatNotifBossProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Kotak Masuk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: listNotifAsync.when(
        data: (listData) {
          // Tampilan jika belum ada transaksi sama sekali
          if (listData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi masuk',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Tampilan daftar notifikasi
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: listData.length,
            itemBuilder: (context, index) {
              final data = listData[index];
              
              // 1. Parsing tanggal agar aman
              DateTime tgl = DateTime.now();
              if (data['tgl_pencatatan'] != null) {
                tgl = DateTime.parse(data['tgl_pencatatan']).toLocal();
              }
              
              // 2. Sulap UI: Ubah angka menjadi format rupiah
              final String totalRupiah = AppFormatters.rupiah(data['total_harga'] ?? 0);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.blue.shade50),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    radius: 24,
                    child: Icon(Icons.assignment_turned_in, color: Colors.blue[600], size: 26),
                  ),
                  title: const Text(
                    '✅ Pencatatan Selesai!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ini adalah teks notifikasi tiruannya
                        Text(
                          'Petugas telah menyelesaikan input pengadaan sparepart senilai $totalRupiah.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(tgl),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // Nantinya, tombol ini bisa Anda arahkan untuk membuka detail nota
                    // Misalnya: context.push('/detail-transaksi', extra: data['id_pencatatan']);
                  },
                ),
              );
            },
          );
        },
        // Tampilan saat sedang loading menarik data
        loading: () => const Center(child: CircularProgressIndicator()),
        // Tampilan jika terjadi error pada database
        error: (err, stack) => Center(
          child: Text('Terjadi kesalahan: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}