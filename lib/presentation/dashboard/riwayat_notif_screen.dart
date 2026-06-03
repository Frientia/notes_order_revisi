import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/riwayat_notif_boss_provider.dart'; 
import '../../domain/providers/read_notif_provider.dart'; // Import provider baru
import '../../core/utils/formatters.dart';

class RiwayatNotifScreen extends ConsumerWidget {
  const RiwayatNotifScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listNotifAsync = ref.watch(riwayatNotifBossProvider);
    // Pantau daftar ID yang sudah dibaca
    final readNotifs = ref.watch(readNotificationsProvider); 

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
              
              // Cek apakah ID transaksi ini ada di dalam daftar yang sudah dibaca
              final bool isRead = readNotifs.contains(idTransaksi);
              
              DateTime tgl = DateTime.now();
              if (data['tgl_pencatatan'] != null) {
                tgl = DateTime.parse(data['tgl_pencatatan']).toLocal();
              }
              final String totalRupiah = AppFormatters.rupiah(data['total_harga'] ?? 0);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  // Jika sudah dibaca, background jadi abu-abu muda. Jika belum, putih bersih.
                  color: isRead ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isRead ? [] : [ // Hilangkan bayangan jika sudah dibaca
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  // Ganti warna border: abu-abu redup (sudah dibaca) vs biru muda (belum dibaca)
                  border: Border.all(color: isRead ? Colors.grey.shade300 : Colors.blue.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    // Warna ikon memudar jika sudah dibaca
                    backgroundColor: isRead ? Colors.grey[300] : Colors.blue[50],
                    radius: 24,
                    child: Icon(
                      isRead ? Icons.drafts : Icons.mark_email_unread, 
                      color: isRead ? Colors.grey[600] : Colors.blue[600], 
                      size: 24
                    ),
                  ),
                  title: Text(
                    '✅ Pencatatan Selesai!',
                    style: TextStyle(
                      // Jika belum dibaca, teks akan tebal (Bold) dan hitam pekat
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
                          style: TextStyle(
                            fontSize: 13, 
                            color: isRead ? Colors.grey[500] : Colors.grey[800], 
                            height: 1.4
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: isRead ? Colors.grey[400] : Colors.blueGrey[400]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy • HH:mm').format(tgl),
                              style: TextStyle(
                                fontSize: 12, 
                                color: isRead ? Colors.grey[400] : Colors.blueGrey[600],
                                fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // 1. Tandai sebagai sudah dibaca (simpan ke memori HP)
                    ref.read(readNotificationsProvider.notifier).markAsRead(idTransaksi);
                    
                    // 2. Lempar Boss ke halaman detail riwayat
                    context.push('/riwayat-boss'); 
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
}