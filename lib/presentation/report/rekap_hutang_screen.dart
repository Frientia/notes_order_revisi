import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/rekap_hutang_provider.dart';
import '../../core/utils/formatters.dart';

class RekapHutangScreen extends ConsumerStatefulWidget {
  const RekapHutangScreen({super.key});

  @override
  ConsumerState<RekapHutangScreen> createState() => _RekapHutangScreenState();
}

class _RekapHutangScreenState extends ConsumerState<RekapHutangScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchHutangProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hutangFilteredState = ref.watch(rekapHutangFilteredProvider);
    final keywordPencarian = ref.watch(searchHutangProvider);
    final filterBulanAktif = ref.watch(bulanHutangProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Rekap Hutang Toko',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: filterBulanAktif != null ? Colors.amber : Colors.white,
            ),
            tooltip: 'Filter & Urutkan',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                ref.watch(rekapHutangRawProvider).when(
                      data: (listMentah) {
                        // --- PERBAIKAN 1: Filter data berdasarkan bulan aktif ---
                        final dataBulanIni = filterBulanAktif == null
                            ? listMentah
                            : listMentah.where(
                                (item) =>
                                    item.tglPencatatan.year == filterBulanAktif.year &&
                                    item.tglPencatatan.month == filterBulanAktif.month,
                              );

                        // --- PERBAIKAN 2: GRAND TOTAL HANYA MENGHITUNG YANG STATUSNYA 'PENDING' ---
                        final totalHutangTeks = dataBulanIni.fold<double>(
                          0,
                          (sum, item) => sum + (item.status == 'PENDING' ? item.subtotal : 0.0),
                        );

                        // Membuat label dinamis untuk Grand Total
                        String labelTotal = 'Total Hutang Berjalan (Semua)';
                        if (filterBulanAktif != null) {
                          final namaBulan = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                            'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
                          ];
                          labelTotal =
                              'Hutang Periode: ${namaBulan[filterBulanAktif.month - 1]} ${filterBulanAktif.year}';
                        }

                        return Column(
                          children: [
                            Text(
                              labelTotal,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppFormatters.rupiah(totalHutangTeks),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const Text('Gagal memuat ringkasan dana'),
                    ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama toko suku cadang...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: keywordPencarian.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchHutangProvider.notifier).state = '';
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) =>
                      ref.read(searchHutangProvider.notifier).state = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: hutangFilteredState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Terjadi kesalahan:\n$err')),
              data: (listData) {
                if (listData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada tagihan hutang ditemukan',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(rekapHutangRawProvider);
                    return ref.read(rekapHutangRawProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: listData.length,
                    itemBuilder: (context, index) {
                      final item = listData[index];
                      // Menentukan warna dinamis card jika toko tersebut sudah lunas di periode filter
                      final bool isTokoLunas = item.totalHutang == 0;

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isTokoLunas ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                            child: Icon(
                              Icons.store,
                              color: isTokoLunas ? Colors.green : Colors.red,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            item.namaToko,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              isTokoLunas ? 'Semua komponen terbayar' : '${item.jumlahItemPending} barang pending',
                              style: TextStyle(fontSize: 13, color: isTokoLunas ? Colors.green : Colors.black87),
                            ),
                          ),
                          trailing: Text(
                            AppFormatters.rupiah(item.totalHutang),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isTokoLunas ? Colors.green : Colors.red,
                            ),
                          ),
                          onTap: () => _showDetailHutangToko(
                            context,
                            item.idToko,
                            item.namaToko,
                            isTokoLunas, // Oper status ke modal detail
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- MENU FILTER BOTTOM SHEET ---
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSort = ref.watch(sortirHutangProvider);
            final currentBulan = ref.watch(bulanHutangProvider);
            final now = DateTime.now();

            final isBulanIni = currentBulan != null && currentBulan.month == now.month && currentBulan.year == now.year;
            final isCustomBulan = currentBulan != null && !isBulanIni;

            final List<String> namaBulanSingkat = [
              'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
            ];
            String labelCustom = 'Pilih Bulan...';
            if (isCustomBulan) {
              labelCustom = '${namaBulanSingkat[currentBulan.month - 1]} ${currentBulan.year}';
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Filter & Urutkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Periode Monitoring', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  // --- PERBAIKAN visual CHIP DI HALAMAN FILTER ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua Waktu'),
                        selected: currentBulan == null, // Aktif jika null
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(bulanHutangProvider.notifier).state = null;
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Bulan Ini'),
                        selected: isBulanIni, // Otomatis aktif saat pertama kali buka aplikasi
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(bulanHutangProvider.notifier).state =
                                DateTime(now.year, now.month);
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 16),
                            const SizedBox(width: 6),
                            Text(labelCustom),
                          ],
                        ),
                        selected: isCustomBulan,
                        onSelected: (selected) =>
                            _showBulanPicker(context, ref),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Urutkan Daftar Toko', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SortirHutang>(
                    value: currentSort,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: const [
                      DropdownMenuItem(value: SortirHutang.tertinggi, child: Text('Hutang Tertinggi (Paling Besar)')),
                      DropdownMenuItem(value: SortirHutang.terendah, child: Text('Hutang Terendah (Paling Kecil)')),
                      DropdownMenuItem(value: SortirHutang.abjad, child: Text('Nama Toko (A - Z)')),
                    ],
                    onChanged: (val) => ref.read(sortirHutangProvider.notifier).state = val!,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBulanPicker(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final List<DateTime> pastMonths = List.generate(12, (index) => DateTime(now.year, now.month - index, 1));
    final namaBulanPanjang = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Bulan Spesifik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pastMonths.length,
              itemBuilder: (ctx, i) {
                final date = pastMonths[i];
                final text = '${namaBulanPanjang[date.month - 1]} ${date.year}';

                return ListTile(
                  leading: const Icon(Icons.date_range, color: Colors.indigo),
                  title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    ref.read(bulanHutangProvider.notifier).state = date;
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- MUNCULKAN RINCIAN NOTA DENGAN LABEL LUNAS DINAMIS ---
  void _showDetailHutangToko(
    BuildContext context,
    int idToko,
    String namaToko,
    bool isTokoLunas,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.70,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),

                // HEADER MODAL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Hutang: $namaToko',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // --- PERBAIKAN 3: TOMBOL LUNASKAN OTOMATIS BERUBAH JIKA PERIODE SUDAH BERES ---
                      isTokoLunas
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Text('Semua Terbayar', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          : Consumer(
                              builder: (context, ref, child) {
                                return ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Lunaskan', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('Konfirmasi Pelunasan', style: TextStyle(fontWeight: FontWeight.bold)),
                                        content: Text('Apakah Anda yakin sudah melakukan pembayaran penuh ke $namaToko untuk periode ini?\n\nSemua nota menggantung di bawah ini akan diubah status menjadi LUNAS.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                            onPressed: () async {
                                              Navigator.of(dialogCtx).pop();
                                              try {
                                                final filterBulan = ref.read(bulanHutangProvider);
                                                await ref.read(aksiHutangProvider).lunaskanSemuaBulanIni(idToko, filterBulan);
                                                if (context.mounted) Navigator.pop(sheetContext);
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
                                                }
                                              }
                                            },
                                            child: const Text('Ya, Lunaskan'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
                const Divider(height: 16),

                // DAFTAR AKORDION NOTA UTUT
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final detailState = ref.watch(detailHutangTokoProvider(idToko));

                      return detailState.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('Gagal memuat rincian:\n$err')),
                        data: (listGrupNota) {
                          if (listGrupNota.isEmpty) {
                            return const Center(child: Text('Tidak ada rincian data ditemukan.'));
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: listGrupNota.length,
                            itemBuilder: (context, index) {
                              final grup = listGrupNota[index];
                              final tglFormat = DateFormat('dd MMM yyyy').format(grup.tanggal);

                              // Hitung apakah di dalam SATU NOTA ini semua item barangnya sudah lunas
                              final bool isNotaIniLunas = grup.totalHutangNota == 0;

                              return Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isNotaIniLunas ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: isNotaIniLunas ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Nota ID: #${grup.idNota}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      '$tglFormat • ${grup.jumlahMacamBarang} Jenis Barang',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    trailing: Text(
                                      isNotaIniLunas ? '✓ Lunas' : AppFormatters.rupiah(grup.totalHutangNota),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isNotaIniLunas ? Colors.green : Colors.red,
                                        fontSize: 15,
                                      ),
                                    ),
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Divider(height: 16),
                                            const Text(
                                              'Rincian Pembelian:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // --- PERBAIKAN 4: LOGIKA TAMPILAN ITEM BARANG DINAMIS ---
                                            ...grup.rincianBarang.map((item) {
                                              final bool isItemLunas = item['status'] == 'SELESAI' || item['status'] == 'LUNAS';

                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '• ',
                                                      style: TextStyle(color: isItemLunas ? Colors.grey : Colors.red, fontWeight: FontWeight.bold),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item['nama_barang'],
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 14,
                                                              color: isItemLunas ? Colors.grey : Colors.black87,
                                                              decoration: isItemLunas ? TextDecoration.lineThrough : null, // Coret tulisan jika lunas
                                                            ),
                                                          ),
                                                          Text(
                                                            '${item['qty']} x ${AppFormatters.rupiah(item['harga'])}',
                                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          AppFormatters.rupiah(item['subtotal']),
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 13,
                                                            color: isItemLunas ? Colors.grey : Colors.black87,
                                                            decoration: isItemLunas ? TextDecoration.lineThrough : null,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        // Tanda visual lunas di ujung item barang
                                                        Icon(
                                                          isItemLunas ? Icons.check_circle : Icons.pending_actions,
                                                          size: 16,
                                                          color: isItemLunas ? Colors.green : Colors.orange,
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              );
                                            }),
                                            const SizedBox(height: 12),
                                            
                                            // Tombol Bukti Kwitansi Nota Utama
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.image, size: 18),
                                                label: const Text('Lihat Foto Kwitansi', style: TextStyle(fontWeight: FontWeight.bold)),
                                                style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo, side: const BorderSide(color: Colors.indigo), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                onPressed: () => _showKwitansiDialog(context, ref, grup.idNota, tglFormat, grup.totalHutangNota),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showKwitansiDialog(BuildContext context, WidgetRef ref, int idNota, String tanggal, double totalHutang) {
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
                children: [
                  const Text('Bukti Kwitansi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ID Nota:', style: TextStyle(color: Colors.grey)),
                      Text('#$idNota', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tanggal:', style: TextStyle(color: Colors.grey)),
                      Text(tanggal, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      final urlState = ref.watch(urlKwitansiProvider(idNota));
                      return urlState.when(
                        loading: () => const Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()),
                        error: (err, stack) => const Text('Gagal memuat gambar kwitansi.', style: TextStyle(color: Colors.red)),
                        data: (url) {
                          if (url == null || url.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                              child: const Column(
                                children: [
                                  Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text('Tidak ada foto kwitansi di-upload.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800], foregroundColor: Colors.white),
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
}