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

    return hutangFilteredState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Terjadi kesalahan:\n$err'))),
      data: (listData) {
        // Memisahkan data Toko Aktif vs Toko Lunas
        final listHutangAktifOnly = listData.where((toko) => toko.totalHutang > 0).toList();
        final listLunasOnly = listData.where((toko) => toko.totalHutang == 0 && toko.jumlahItemPending == 0).toList();

        // Menggunakan DefaultTabController agar layout terbagi jadi 2 Tab menarik
        return DefaultTabController(
          length: 2,
          child: Scaffold(
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
                // Ringkasan Header Dana & Search Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 12),
                      
                      // ─── TABBAR MODERN DENGAN BADGE BADGE TOTAL TOKO ───
                      TabBar(
                        labelColor: primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: primaryColor,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Belum Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                CircleAvatar(
                                  radius: 9,
                                  backgroundColor: listHutangAktifOnly.isNotEmpty ? Colors.red : Colors.grey.shade300,
                                  child: Text('${listHutangAktifOnly.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Riwayat Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                CircleAvatar(
                                  radius: 9,
                                  backgroundColor: listLunasOnly.isNotEmpty ? Colors.green : Colors.grey.shade300,
                                  child: Text('${listLunasOnly.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ISI KONTEN PER TAB LAYAR
                Expanded(
                  child: TabBarView(
                    children: [
                      // KONTEN TAB 1: DAFTAR TOKO BELUM LUNAS
                      _buildTokoList(listHutangAktifOnly, false),
                      
                      // KONTEN TAB 2: DAFTAR TOKO SUDAH LUNAS
                      _buildTokoList(listLunasOnly, true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // REFACTOR WIDGET LIST BIAR GAK REDUNDANT
  Widget _buildTokoList(List<RekapHutangModel> listToko, bool isTabLunas) {
    if (listToko.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTabLunas ? Icons.history_toggle_off_rounded : Icons.verified_user_rounded,
              size: 56,
              color: isTabLunas ? Colors.grey[400] : Colors.green[400],
            ),
            const SizedBox(height: 12),
            Text(
              isTabLunas ? 'Belum ada riwayat pelunasan transfer' : 'Luar Biasa, Boss! Semua Toko Sudah Lunas.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              textAlign: TextAlign.center,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: listToko.length,
        itemBuilder: (context, index) {
          final item = listToko[index];

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: isTabLunas ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                child: Icon(Icons.store, color: isTabLunas ? Colors.green : Colors.red, size: 22),
              ),
              title: Text(item.namaToko, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  isTabLunas ? 'Semua komponen terbayar (Cek TF)' : '${item.jumlahItemPending} barang pending hutang',
                  style: TextStyle(fontSize: 13, color: isTabLunas ? Colors.green[700] : Colors.black87),
                ),
              ),
              trailing: Text(
                isTabLunas ? 'Lunas' : AppFormatters.rupiah(item.totalHutang),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isTabLunas ? Colors.green : Colors.red),
              ),
              onTap: () => _showDetailHutangToko(context, item.idToko, item.namaToko, isTabLunas),
            ),
          );
        },
      ),
    );
  }

  // --- MODAL RINCIAN DETAIL (SINKRON DENGAN TOMBOL LIHAT BUKTI TF DINAMIS JIKA LUNAS) ---
  void _showDetailHutangToko(BuildContext context, int idToko, String namaToko, bool isTokoLunas) {
    const primaryColor = Color(0xFF1E3A5F);
    Uint8List? fileBytesTransfer;
    String? namaFileTransfer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
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
                          Expanded(child: Text(isTokoLunas ? 'Arsip: $namaToko' : 'Tagihan: $namaToko', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                          
                          // IMPLEMENTASI FITUR CEK BUKTI TRANSFER JIKA SUDAH LUNAS
                          isTokoLunas
                              ? InkWell(
                                  onTap: () {
                                    Navigator.pop(sheetContext); 
                                    _showGambarTransferDialog(context, idToko, namaToko); 
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.remove_red_eye, color: Colors.green, size: 14),
                                        SizedBox(width: 4),
                                        Text('Lihat Bukti TF', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
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
                              final listHutangOnly = isTokoLunas 
                                  ? listGrupNota 
                                  : listGrupNota.where((g) => g.totalHutangNota > 0).toList();

                              if (listHutangOnly.isEmpty) {
                                return const Center(child: Text('Tidak ada rincian nota ditemukan.'));
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: listHutangOnly.length,
                                itemBuilder: (context, index) {
                                  final grup = listHutangOnly[index];
                                  final tglFormat = DateFormat('dd MMM yyyy').format(grup.tanggal);

                                  // LOGIKA ALARM REMINDER JATUH TEMPO H-3
                                  bool isDaruratJatuhTempo = false;
                                  String teksSisaHari = '';
                                  
                                  if (grup.tglJatuhTempo != null && !isTokoLunas) {
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
                                      leading: Icon(Icons.receipt_long, color: isTokoLunas ? Colors.green : (isDaruratJatuhTempo ? Colors.red : Colors.orange)),
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
                                      trailing: Text(isTokoLunas ? '✓ Lunas' : AppFormatters.rupiah(grup.totalHutangNota), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isTokoLunas ? Colors.green : Colors.red)),
                                      children: [
                                        Container(
                                          width: double.infinity, padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ...grup.rincianBarang.map((item) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 4.0),
                                                  child: Text('• ${item['nama_barang']} (${item['qty']}x) = ${AppFormatters.rupiah(item['subtotal'])}', style: TextStyle(fontSize: 13, decoration: isTokoLunas ? TextDecoration.lineThrough : null, color: isTokoLunas ? Colors.grey : Colors.black87)),
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

                    // BOX UPLOAD FOTO BUKTI TF (SEMBUNYIKAN JIKA SUDAH LUNAS)
                    if (!isTokoLunas)
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
                                    setModalState(() { 
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
                
                await ref.read(aksiHutangProvider).lunaskanDenganBuktiTf(
                  idToko: idToko,
                  periodeBulan: filterBulan ?? DateTime.now(),
                  imageBytes: bytes,
                  imageName: namaFile,
                );

                ref.invalidate(rekapHutangRawProvider); 
                if (screenCtx.mounted) {
                  Navigator.pop(sheetCtx); 
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

  void _showGambarTransferDialog(BuildContext context, int idToko, String namaToko) {
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
                  Text(
                    'Bukti Pelunasan $namaToko',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 24),
                  
                  Consumer(
                    builder: (context, ref, child) {
                      final transferUrlState = ref.watch(urlBuktiTransferProvider(idToko));
                      
                      return transferUrlState.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => const Text(
                          'Gagal memuat file bukti transfer.',
                          style: TextStyle(color: Colors.red),
                        ),
                        data: (url) {
                          if (url == null || url.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text('Arsip gambar transfer tidak ditemukan.', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }
                          
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F), foregroundColor: Colors.white),
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