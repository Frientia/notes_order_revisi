import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/riwayat_repository.dart';
import '../../core/utils/formatters.dart';

class DetailRiwayatScreen extends ConsumerWidget {
  final int idPencatatan;
  const DetailRiwayatScreen({super.key, required this.idPencatatan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailRiwayatProvider(idPencatatan));

    return Scaffold(
      appBar: AppBar(title: Text('Detail Transaksi #$idPencatatan')),
      body: detailAsync.when(
        data: (listDetail) {
          if (listDetail.isEmpty) return const Center(child: Text('Detail tidak ditemukan.'));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listDetail.length,
            itemBuilder: (context, index) {
              final item = listDetail[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.namaBarang, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.status == 'SELESAI' ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.status == 'SELESAI' ? 'LUNAS' : 'HUTANG', 
                              style: TextStyle(color: item.status == 'SELESAI' ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold)
                            ),
                          )
                        ],
                      ),
                      const Divider(),
                      
                      _buildDetailRow(Icons.store, 'Toko', item.namaToko),
                      _buildDetailRow(Icons.directions_car, 'Mobil', item.noPlatMobil),
                      _buildDetailRow(Icons.format_list_numbered, 'Kuantitas', '${item.qty} x ${AppFormatters.rupiah(item.hargaPembelian)}'),
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                              Text(AppFormatters.rupiah(item.subtotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showImageDialog(context, item.imgKwitansi),
                            icon: const Icon(Icons.receipt),
                            label: const Text('Lihat Kwitansi'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$title: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String? imgUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Foto Kwitansi', style: TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))],
            ),
            if (imgUrl == null || imgUrl.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Text('Tidak ada gambar kwitansi.'))
            else
              InteractiveViewer(
                child: Image.network(imgUrl, fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator());
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}