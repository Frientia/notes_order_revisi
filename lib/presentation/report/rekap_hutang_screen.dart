import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
    // PERBAIKAN 2: Set default filter ke null agar memantau SEMUA BULAN secara universal saat dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bulanHutangProvider.notifier).state = null;
    });
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
    const primaryColor = Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Rekap Hutang Toko', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: filterBulanAktif != null ? Colors.amber : Colors.white),
            tooltip: 'Filter Periode',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ringkasan Header Dana
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
                    final dataFilter = filterBulanAktif == null
                        ? listMentah
                        : listMentah.where((item) =>
                            item.tglPencatatan.year == filterBulanAktif.year &&
                            item.tglPencatatan.month == filterBulanAktif.month);

                    // Menghitung grand total hanya dari item yang belum lunas (status PENDING)
                    final totalHutangTeks = dataFilter.fold<double>(
                      0, (sum, item) => sum + (item.status == 'PENDING' ? item.subtotal : 0.0),
                    );

                    String labelTotal = 'Total Hutang Berjalan (Semua Periode)';
                    if (filterBulanAktif != null) {
                      labelTotal = 'Hutang Periode: ${DateFormat('MMM yyyy').format(filterBulanAktif)}';
                    }

                    return Column(
                      children: [
                        Text(labelTotal, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(AppFormatters.rupiah(totalHutangTeks), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 1.5)),
                    filled: true, fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => ref.read(searchHutangProvider.notifier).state = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Daftar List Toko
          Expanded(
            child: hutangFilteredState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Terjadi kesalahan:\n$err')),
              data: (listData) {
                // PERBAIKAN 1: Filter ketat di UI, jika totalHutang == 0 (LUNAS), langsung tendang keluar dari daftar visual
                final listHutangAktifOnly = listData.where((toko) => toko.totalHutang > 0).toList();

                if (listHutangAktifOnly.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 60, color: Colors.green[400]),
                        const SizedBox(height: 12),
                        const Text('Luar Biasa, Boss! Semua Toko Sudah Lunas.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                    itemCount: listHutangAktifOnly.length,
                    itemBuilder: (context, index) {
                      final item = listHutangAktifOnly[index];

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.red.withOpacity(0.08),
                            child: const Icon(Icons.store, color: Colors.red, size: 22),
                          ),
                          title: Text(item.namaToko, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('${item.jumlahItemPending} barang pending hutang', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          ),
                          trailing: Text(AppFormatters.rupiah(item.totalHutang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                          onTap: () => _showDetailHutangToko(context, item.idToko, item.namaToko),
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

  // --- MODAL RINCIAN DETAIL (SUNTIK FITUR REMINDER H-3 & PILIH TRANSFER) ---
  void _showDetailHutangToko(BuildContext context, int idToko, String namaToko) {
    const primaryColor = Color(0xFF1E3A5F); // <--- TAMBAHKAN BARIS INI, BOSS!
    Uint8List? fileBytesTransfer;
    String? namaFileTransfer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder( // Agar local state modal bottom sheet bisa di-render ulang pas upload gambar
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.80,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 16),

                    // HEADER MODAL RETAIL
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('Tagihan: $namaToko', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                          
                          // TOMBOL AKSI PROSES PELUNASAN KETAT
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: fileBytesTransfer != null ? Colors.green : Colors.grey[400],
                              foregroundColor: Colors.white, elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                            ),
                            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                            label: const Text('Lunaskan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: fileBytesTransfer == null 
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('⚠️ Boss, wajib upload foto bukti TF dulu di tombol bawah sebelum pelunasan!'), backgroundColor: Colors.orange)
                                  );
                                }
                              : () => _konfirmasiPelunasanFinal(context, idToko, namaToko, fileBytesTransfer!, namaFileTransfer!, sheetContext),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),

                    // DAFTAR ITEM KARTU NOTA BAWAHAN
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final detailState = ref.watch(detailHutangTokoProvider(idToko));

                          return detailState.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Center(child: Text('Gagal memuat rincian: $err')),
                            data: (listGrupNota) {
                              // Filter visual di detail agar nota yang sudah lunas tidak tampil mengotori list
                              final listHutangOnly = listGrupNota.where((g) => g.totalHutangNota > 0).toList();

                              if (listHutangOnly.isEmpty) {
                                return const Center(child: Text('Semua rincian nota periode ini bersih terbayar.'));
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: listHutangOnly.length,
                                itemBuilder: (context, index) {
                                  final grup = listHutangOnly[index];
                                  final tglFormat = DateFormat('dd MMM yyyy').format(grup.tanggal);

                                  // ─── PERBAIKAN 3: LOGIKA ALARM REMINDER JATUH TEMPO H-3 ───
                                  bool isDaruratJatuhTempo = false;
                                  String teksSisaHari = '';
                                  
                                  if (grup.tglJatuhTempo != null) {
                                    final skrg = DateTime.now();
                                    final selisihHari = grup.tglJatuhTempo!.difference(DateTime(skrg.year, skrg.month, skrg.day)).inDays;
                                    
                                    if (selisihHari <= 3) {
                                      isDaruratJatuhTempo = true;
                                      teksSisaHari = selisihHari == 0 ? 'HARI INI JATUH TEMPO!' : '$selisihHari Hari Lagi Tempo';
                                    } else {
                                      teksSisaHari = 'Tempo: ${DateFormat('dd/MM/yy').format(grup.tglJatuhTempo!)}';
                                    }
                                  }

                                  return Card(
                                    elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDaruratJatuhTempo ? Colors.red.shade300 : Colors.grey.shade200, width: isDaruratJatuhTempo ? 1.5 : 1)),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                                      leading: Icon(Icons.receipt_long, color: isDaruratJatuhTempo ? Colors.red : Colors.orange),
                                      title: Row(
                                        children: [
                                          Text('Nota #${grup.idNota}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          if (isDaruratJatuhTempo) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                              child: Text(teksSisaHari, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            )
                                          ]
                                        ],
                                      ),
                                      subtitle: Text('$tglFormat • ${grup.jumlahMacamBarang} Suku Cadang', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      trailing: Text(AppFormatters.rupiah(grup.totalHutangNota), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                                      children: [
                                        Container(
                                          width: double.infinity, padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ...grup.rincianBarang.map((item) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 4.0),
                                                  child: Text('• ${item['nama_barang']} (${item['qty']}x) = ${AppFormatters.rupiah(item['subtotal'])}', style: const TextStyle(fontSize: 13)),
                                                );
                                              }),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // ─── PERBAIKAN 4: BOX WIDGET UPLOAD FOTO BUKTI TF TRANSFER ───
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey[50], border: Border(top: BorderSide(color: Colors.grey.shade200))),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: fileBytesTransfer != null ? Colors.green[800] : primaryColor,
                                side: BorderSide(color: fileBytesTransfer != null ? Colors.green : primaryColor),
                                backgroundColor: fileBytesTransfer != null ? Colors.green[50] : Colors.transparent,
                                minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                              ),
                              icon: Icon(fileBytesTransfer != null ? Icons.check_circle : Icons.camera_alt),
                              label: Text(fileBytesTransfer != null ? 'Bukti TF Siap' : 'Upload Bukti Transfer (Wajib)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 65);
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  setModalState(() { // Memicu build ulang internal dialog/sheet saja
                                    fileBytesTransfer = bytes;
                                    namaFileTransfer = image.name;
                                  });
                                }
                              },
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
  }

  // LOGIKA AKSI LUNAS DIKUNCI TRANSFER
  void _konfirmasiPelunasanFinal(BuildContext screenCtx, int idToko, String namaToko, Uint8List bytes, String namaFile, BuildContext sheetCtx) {
    showDialog(
      context: screenCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Eksekusi Pelunasan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Boss yakin ingin melunaskan seluruh total hutang pada $namaToko?\n\nSistem akan mengupload bukti transfer fisik dan otomatis menutup seluruh nota.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final filterBulan = ref.read(bulanHutangProvider);
                
                // 1. Eksekusi upload gambar bukti tf & update status database secara kolektif
                await ref.read(aksiHutangProvider).lunaskanDenganBuktiTf(
                  idToko: idToko,
                  periodeBulan: filterBulan ?? DateTime.now(),
                  imageBytes: bytes,
                  imageName: namaFile,
                );

                ref.invalidate(rekapHutangRawProvider); // Reset data screen utama
                if (screenCtx.mounted) {
                  Navigator.pop(sheetCtx); // Tutup bottom sheet detail
                  ScaffoldMessenger.of(screenCtx).showSnackBar(
                    SnackBar(content: Text('Sukses melunaskan hutang $namaToko dan menyimpan arsip transfer!'), backgroundColor: Colors.green[800])
                  );
                }
              } catch (e) {
                if (screenCtx.mounted) {
                  ScaffoldMessenger.of(screenCtx).showSnackBar(SnackBar(content: Text('Gagal eksekusi: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Ya, Bayar Lunas'),
          ),
        ],
      ),
    );
  }

  // --- SELECTION BULAN ---
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSort = ref.watch(sortirHutangProvider);
            final currentBulan = ref.watch(bulanHutangProvider);

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('Filter Periode Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua Periode Waktu'),
                        selected: currentBulan == null,
                        onSelected: (selected) { if (selected) ref.read(bulanHutangProvider.notifier).state = null; },
                      ),
                      ChoiceChip(
                        label: const Text('Filter Bulan Spesifik'),
                        selected: currentBulan != null,
                        onSelected: (selected) => _showBulanPicker(context, ref),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Urutkan Daftar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SortirHutang>(
                    value: currentSort,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: const [
                      DropdownMenuItem(value: SortirHutang.tertinggi, child: Text('Hutang Tertinggi')),
                      DropdownMenuItem(value: SortirHutang.terendah, child: Text('Hutang Terendah')),
                      DropdownMenuItem(value: SortirHutang.abjad, child: Text('Nama Toko (A - Z)')),
                    ],
                    onChanged: (val) => ref.read(sortirHutangProvider.notifier).state = val!,
                  ),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Bulan'),
        content: SizedBox(
          width: double.maxFinite, height: 250,
          child: ListView.builder(
            itemCount: pastMonths.length,
            itemBuilder: (ctx, i) {
              final date = pastMonths[i];
              return ListTile(
                leading: const Icon(Icons.date_range, color: Colors.indigo),
                title: Text(DateFormat('MMMM yyyy').format(date)),
                onTap: () {
                  ref.read(bulanHutangProvider.notifier).state = date;
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}