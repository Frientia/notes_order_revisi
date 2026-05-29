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
      backgroundColor: const Color(0xFFF0F2F5), // Latar belakang abu-abu sangat muda khas aplikasi modern
      appBar: AppBar(
        backgroundColor: const Color(0xFF25313A), // Warna gelap elegan sesuai gambar
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          // TOMBOL CETAK / EKSPOR
          riwayatAsync.maybeWhen(
            data: (listRiwayat) => PopupMenuButton<String>(
              icon: const Icon(Icons.print, color: Colors.white),
              tooltip: 'Cetak Laporan',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          // 1. BAGIAN HEADER (SEARCH BAR VISUAL)
          Container(
            color: const Color(0xFF25313A),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari barang, nopol, atau petugas...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. BAGIAN FILTER CHIPS (HORIZONTAL SCROLL)
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Bulan Ini', 'Bulan Lalu', '2 Bulan Lalu', 'Semua Waktu'].map((filterItem) {
                  final isSelected = currentFilter == filterItem;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => ref.read(riwayatFilterProvider.notifier).state = filterItem,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFDCE2FA) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check, size: 16, color: Color(0xFF3B56B9)),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              filterItem,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF3B56B9) : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // 3. BAGIAN KONTEN (SUMMARY KARTU BIRU & LIST RIWAYAT)
          Expanded(
            child: riwayatAsync.when(
              data: (listRiwayat) {
                if (listRiwayat.isEmpty) {
                  return const Center(child: Text('Tidak ada transaksi pada periode ini.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)));
                }

                // Kalkulasi Grand Total untuk Summary Card
                double grandTotalPeriode = listRiwayat.fold(0, (sum, item) => sum + item.totalHarga);
                
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // KARTU SUMMARY BIRU
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A55A2), Color(0xFF3B56B9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF3B56B9).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pengeluaran (Periode Filter)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(
                            AppFormatters.rupiah(grandTotalPeriode), 
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text('${listRiwayat.length} Transaksi Tercatat', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          )
                        ],
                      ),
                    ),

                    // LIST ITEM TRANSAKSI
                    ...listRiwayat.map((riwayat) {
                      // Ambil detail pertama sebagai cuplikan UI
                      final detailPreview = riwayat.details.isNotEmpty ? riwayat.details.first : null;
                      final sisaItem = riwayat.details.length > 1 ? riwayat.details.length - 1 : 0;

                      return GestureDetector(
                        onTap: () => context.push('/detail-riwayat', extra: riwayat.idPencatatan),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Item: Nota, Tanggal & Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'NOTA #${riwayat.idPencatatan} • ${AppFormatters.waktu(riwayat.tglPencatatan)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F4EA),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('SELESAI', style: TextStyle(color: Color(0xFF1E8E3E), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Judul Barang
                              Text(
                                detailPreview != null 
                                    ? '${detailPreview.namaBarang}${sisaItem > 0 ? ' (+$sisaItem item lain)' : ''}' 
                                    : 'Tidak ada detail barang',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),

                              // Info Tags (Toko & Mobil)
                              if (detailPreview != null)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: Row(
                                        children: [
                                          Icon(Icons.store, size: 12, color: Colors.grey.shade700),
                                          const SizedBox(width: 4),
                                          Text(detailPreview.namaToko, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(6)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.directions_car, size: 12, color: Color(0xFF00897B)),
                                          const SizedBox(width: 4),
                                          Text(detailPreview.noPlatMobil, style: const TextStyle(fontSize: 12, color: Color(0xFF00897B), fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),

                              // Footer: Petugas & Harga
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.grey.shade400),
                                      const SizedBox(width: 6),
                                      Text('Petugas Logistik', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Total Belanja', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                      Text(
                                        AppFormatters.rupiah(riwayat.totalHarga),
                                        style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
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