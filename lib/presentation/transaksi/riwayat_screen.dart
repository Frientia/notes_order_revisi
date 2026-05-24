import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/riwayat_repository.dart';
import '../../core/utils/formatters.dart';

class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riwayatAsync = ref.watch(riwayatListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: riwayatAsync.when(
        data: (listRiwayat) {
          if (listRiwayat.isEmpty) return const Center(child: Text('Belum ada transaksi.'));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listRiwayat.length,
            itemBuilder: (context, index) {
              final riwayat = listRiwayat[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.receipt_long, color: Colors.white),
                  ),
                  title: Text(AppFormatters.waktu(riwayat.tglPencatatan), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID Transaksi: ${riwayat.idPencatatan}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppFormatters.rupiah(riwayat.totalHarga), 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    context.push('/detail-riwayat', extra: riwayat.idPencatatan);
                  },
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
}