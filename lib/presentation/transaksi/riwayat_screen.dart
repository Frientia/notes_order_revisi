import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/riwayat_repository.dart';
import '../../data/models/riwayat_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_generator.dart';

// 1. Provider State untuk menyimpan status Filter Waktu saat ini
final riwayatFilterProvider = StateProvider<String>((ref) => 'Bulan Ini');

// 2. Provider Data Riwayat yang bereaksi terhadap perubahan Filter
final filteredRiwayatProvider = FutureProvider.autoDispose<List<PencatatanModel>>((ref) async {
  final filter = ref.watch(riwayatFilterProvider);
  final repo = ref.watch(riwayatRepositoryProvider);
  
  DateTime now = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;

  if (filter == 'Bulan Ini') {
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  } else if (filter == 'Bulan Lalu') {
    startDate = DateTime(now.year, now.month - 1, 1);
    endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
  } else if (filter == '2 Bulan Lalu') {
    startDate = DateTime(now.year, now.month - 2, 1);
    endDate = DateTime(now.year, now.month - 1, 0, 23, 59, 59);
  } 
  // Jika 'Semua Waktu', biarkan null

  return repo.getRiwayat(startDate: startDate, endDate: endDate);
});


class RiwayatScreen extends ConsumerWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riwayatAsync = ref.watch(filteredRiwayatProvider);
    final currentFilter = ref.watch(riwayatFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          // TOMBOL CETAK / EKSPOR
          riwayatAsync.maybeWhen(
            data: (listRiwayat) => PopupMenuButton<String>(
              icon: const Icon(Icons.print),
              tooltip: 'Cetak Laporan',
              onSelected: (value) async {
                if (listRiwayat.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk dicetak')));
                  return;
                }
                
                if (value == 'PDF') {
                  await ReportGenerator.generatePDF(currentFilter, listRiwayat);
                } else if (value == 'EXCEL') {
                  await ReportGenerator.generateExcel(currentFilter, listRiwayat);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'PDF', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('Cetak PDF')])),
                const PopupMenuItem(value: 'EXCEL', child: Row(children: [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 8), Text('Export Excel')])),
              ],
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // BAGIAN FILTER DROPDOWN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.grey),
                const SizedBox(width: 12),
                const Text('Periode: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: currentFilter,
                      items: ['Bulan Ini', 'Bulan Lalu', '2 Bulan Lalu', 'Semua Waktu']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(riwayatFilterProvider.notifier).state = val;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // BAGIAN DAFTAR RIWAYAT TRANSAKSI
          Expanded(
            child: riwayatAsync.when(
              data: (listRiwayat) {
                if (listRiwayat.isEmpty) {
                  return const Center(child: Text('Tidak ada transaksi pada periode ini.', style: TextStyle(fontStyle: FontStyle.italic)));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listRiwayat.length,
                  itemBuilder: (context, index) {
                    final riwayat = listRiwayat[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.receipt_long, color: Colors.white),
                        ),
                        title: Text(AppFormatters.waktu(riwayat.tglPencatatan), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID Transaksi: #${riwayat.idPencatatan}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppFormatters.rupiah(riwayat.totalHarga), 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
          ),
        ],
      ),
    );
  }
}