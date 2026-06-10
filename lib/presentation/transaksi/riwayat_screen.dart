import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/riwayat_repository.dart';
import '../../data/models/riwayat_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/report_generator.dart';

final riwayatFilterProvider = StateProvider<String>((ref) => 'Bulan Ini');
final riwayatCustomDateProvider = StateProvider<DateTimeRange?>((ref) => null);
final riwayatSearchProvider = StateProvider<String>((ref) => '');

final filteredRiwayatProvider = FutureProvider.autoDispose<List<PencatatanModel>>((ref) async {
  final filter = ref.watch(riwayatFilterProvider);
  final customDate = ref.watch(riwayatCustomDateProvider);
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
  } else if (filter == 'Kustom' && customDate != null) {
    startDate = customDate.start;
    endDate = DateTime(customDate.end.year, customDate.end.month, customDate.end.day, 23, 59, 59);
  } 

  return repo.getRiwayat(startDate: startDate, endDate: endDate);
});

class RiwayatScreen extends ConsumerStatefulWidget {
  const RiwayatScreen({super.key});

  @override
  ConsumerState<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends ConsumerState<RiwayatScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final initialDateRange = ref.read(riwayatCustomDateProvider) ?? 
        DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now());

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1E3A5F),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      ref.read(riwayatCustomDateProvider.notifier).state = pickedRange;
      ref.read(riwayatFilterProvider.notifier).state = 'Kustom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final riwayatAsync = ref.watch(filteredRiwayatProvider);
    final currentFilter = ref.watch(riwayatFilterProvider);
    final customDate = ref.watch(riwayatCustomDateProvider);
    final searchQuery = ref.watch(riwayatSearchProvider).toLowerCase();
    final primaryColor = const Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, 
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 130,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            actions: [
              riwayatAsync.maybeWhen(
                data: (listRiwayat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
                      child: const Icon(Icons.print, color: Colors.white, size: 20),
                    ),
                    tooltip: 'Cetak Laporan',
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) async {
                      if (listRiwayat.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data untuk dicetak'), backgroundColor: Colors.orange));
                        return;
                      }
                      if (value == 'PDF') {
                        await ReportGenerator.generatePDF(currentFilter, listRiwayat);
                      } else if (value == 'EXCEL') {
                        await ReportGenerator.generateExcel(currentFilter, listRiwayat);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'PDF', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 12), Text('Cetak PDF', style: TextStyle(fontWeight: FontWeight.w600))])),
                      const PopupMenuItem(value: 'EXCEL', child: Row(children: [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 12), Text('Export Excel', style: TextStyle(fontWeight: FontWeight.w600))])),
                    ],
                  ),
                ),
                orElse: () => const SizedBox(),
              ),
            ],
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 48, bottom: 16),
              title: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => ref.read(riwayatSearchProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Cari nota, barang, nopol, atau toko...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    suffixIcon: searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(riwayatSearchProvider.notifier).state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _selectCustomDateRange(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: currentFilter == 'Kustom' ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: currentFilter == 'Kustom' ? primaryColor : Colors.grey.shade300),
                        boxShadow: currentFilter == 'Kustom' ? [BoxShadow(color: primaryColor.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, size: 16, color: currentFilter == 'Kustom' ? Colors.white : Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            currentFilter == 'Kustom' && customDate != null 
                                ? '${DateFormat('dd MMM').format(customDate.start)} - ${DateFormat('dd MMM').format(customDate.end)}'
                                : 'Pilih Tanggal',
                            style: TextStyle(
                              color: currentFilter == 'Kustom' ? Colors.white : Colors.grey.shade700,
                              fontWeight: currentFilter == 'Kustom' ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...['Bulan Ini', 'Bulan Lalu', 'Semua Waktu'].map((filterItem) {
                    final isSelected = currentFilter == filterItem;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => ref.read(riwayatFilterProvider.notifier).state = filterItem,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withAlpha(26) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                          ),
                          child: Text(
                            filterItem,
                            style: TextStyle(
                              color: isSelected ? primaryColor : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          riwayatAsync.when(
            data: (listRiwayat) {
              final displayedRiwayat = listRiwayat.where((riwayat) {
                if (searchQuery.isEmpty) return true;
                if (riwayat.idPencatatan.toString().contains(searchQuery)) return true;
                return riwayat.details.any((detail) {
                  return detail.namaBarang.toLowerCase().contains(searchQuery) ||
                         detail.noPlatMobil.toLowerCase().contains(searchQuery) ||
                         detail.namaToko.toLowerCase().contains(searchQuery);
                });
              }).toList();

              if (listRiwayat.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: const Color(0xFF1E3A5F).withAlpha(20), shape: BoxShape.circle),
                          child: Icon(Icons.history_toggle_off, size: 64, color: const Color(0xFF1E3A5F).withAlpha(80)),
                        ),
                        const SizedBox(height: 24),
                        const Text('Belum Ada Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text('Tidak ada riwayat untuk periode yang dipilih.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }

              if (displayedRiwayat.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Data Tidak Ditemukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text('Coba gunakan kata kunci pencarian yang lain.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }

              double grandTotalPeriode = displayedRiwayat.fold(0, (sum, item) => sum + item.totalHarga);
              
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A55A2), Color(0xFF3B56B9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF3B56B9).withAlpha(77), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            searchQuery.isEmpty ? 'Total Pengeluaran' : 'Total Pengeluaran (Hasil Pencarian)', 
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppFormatters.rupiah(grandTotalPeriode), 
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text('${displayedRiwayat.length} Transaksi Selesai', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    ...displayedRiwayat.map((riwayat) {
                      final detailPreview = riwayat.details.isNotEmpty ? riwayat.details.first : null;
                      final sisaItem = riwayat.details.length > 1 ? riwayat.details.length - 1 : 0;

                      return GestureDetector(
                        onTap: () => context.push('/detail-riwayat', extra: riwayat.idPencatatan),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('NOTA #${riwayat.idPencatatan}', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  Text(
                                    AppFormatters.waktu(riwayat.tglPencatatan),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                detailPreview != null 
                                    ? '${detailPreview.namaBarang}${sisaItem > 0 ? ' (+$sisaItem item)' : ''}' 
                                    : 'Tidak ada detail barang',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              if (detailPreview != null)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: Row(
                                        children: [
                                          Icon(Icons.store, size: 14, color: Colors.grey.shade700),
                                          const SizedBox(width: 6),
                                          Text(detailPreview.namaToko, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: Row(
                                        children: [
                                          Icon(Icons.directions_car, size: 14, color: Colors.blue.shade700),
                                          const SizedBox(width: 6),
                                          Text(detailPreview.noPlatMobil, style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                        child: Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Petugas Logistik', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Total Belanja', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
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
                  ]),
                ),
              );
            },
            loading: () => SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: primaryColor))),
            error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Terjadi kesalahan: $error'))),
          ),
        ],
      ),
    );
  }
}