import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../data/models/barang_model.dart';
import '../../data/models/mobil_model.dart';
import '../../data/models/toko_model.dart';
import '../../data/repositories/transaksi_repository.dart';
import '../../domain/providers/barang_provider.dart';
import '../../domain/providers/mobil_provider.dart';
import '../../domain/providers/toko_provider.dart';
import '../../domain/providers/transaksi_draft_provider.dart';
import '../../core/utils/formatters.dart';

class FormPencatatanScreen extends ConsumerStatefulWidget {
  const FormPencatatanScreen({super.key});

  @override
  ConsumerState<FormPencatatanScreen> createState() => _FormPencatatanScreenState();
}

class _FormPencatatanScreenState extends ConsumerState<FormPencatatanScreen> {
  final _formItemKey = GlobalKey<FormState>();

  // State Filter Kategori (Tetap pakai bawaan karena isinya sedikit)
  BarangKategori? _selectedKategoriBarang;
  MobilKategori? _selectedKategoriMobil;

  // UBAH: State Input Rencana kini menggunakan Objek utuh agar lebih aman
  BarangModel? _selectedBarang;
  MobilModel? _selectedMobil;
  TokoModel? _selectedToko;
  
  final _qtyCtrl = TextEditingController();
  final _hargaEstimasiCtrl = TextEditingController();

  // State Input Lapangan (Riil)
  final Map<int, TextEditingController> _hargaRiilControllers = {};
  final Map<int, String> _statusPembayaranMap = {};
  final Map<int, Uint8List> _kwitansiBytesMap = {};
  final Map<int, String> _kwitansiNameMap = {};

  bool _isSubmitting = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _hargaEstimasiCtrl.dispose();
    for (var ctrl in _hargaRiilControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickKwitansiPerItem(int idDetail) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _kwitansiBytesMap[idDetail] = bytes;
        _kwitansiNameMap[idDetail] = pickedFile.name;
      });
    }
  }

  double _hitungGrandTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      final idDetail = item['id_detail_pencatatan'] as int;
      final inputText = _hargaRiilControllers[idDetail]?.text ?? '';
      final harga = inputText.isNotEmpty 
          ? (double.tryParse(inputText) ?? 0) 
          : (double.tryParse(item['harga_pembelian_barang'].toString()) ?? 0);
      final qty = item['qty'] as int;
      total += (qty * harga);
    }
    return total;
  }

  Future<void> _eksekusiSelesai(int idDraft, List<Map<String, dynamic>> items) async {
    for (var item in items) {
      final idDetail = item['id_detail_pencatatan'] as int;
      final hargaInput = double.tryParse(_hargaRiilControllers[idDetail]?.text ?? '0') ?? 0;
      
      if (hargaInput <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal! Harga riil item "${item['barang']['nama_barang']}" tidak boleh 0.'), backgroundColor: Colors.red),
        );
        return; 
      }

      if (!_kwitansiBytesMap.containsKey(idDetail)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal! Kwitansi untuk item "${item['barang']['nama_barang']}" belum diupload.'), backgroundColor: Colors.red),
        );
        return; 
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final List<Map<String, dynamic>> finalDataPayload = [];

      for (var item in items) {
        final idDetail = item['id_detail_pencatatan'] as int;
        final hargaInput = double.tryParse(_hargaRiilControllers[idDetail]?.text ?? '') ?? 0;
        final statusInput = _statusPembayaranMap[idDetail] ?? 'SELESAI';

        finalDataPayload.add({
          'id_detail_pencatatan': idDetail,
          'harga_pembelian_barang': hargaInput,
          'status': statusInput,
          'image_bytes': _kwitansiBytesMap[idDetail],
          'image_name': _kwitansiNameMap[idDetail],
        });
      }

      final grandTotal = _hitungGrandTotal(items);

      await ref.read(transaksiRepositoryProvider).finalisasiTransaksi(
            idPencatatan: idDraft,
            grandTotal: grandTotal,
            finalItemsData: finalDataPayload,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi Sukses Disimpan ke Riwayat!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

 // --- WIDGET HELPER: DROPDOWN SEARCH CERDAS (VERSI 7.0.0 FINAL) ---
  Widget _buildSearchableDropdownWithShortcut<T>({
    required String label,
    required T? selectedItem,
    required List<T> items,
    required String Function(T) itemAsString,
    required bool Function(T, T) compareFn,
    required Function(T?) onChanged,
    required VoidCallback onAddPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownSearch<T>(
            selectedItem: selectedItem,
            
            // [PERBAIKAN UTAMA]: items sekarang menggunakan fungsi callback
            items: (String filter, LoadProps? loadProps) {
              // Jika kotak pencarian kosong, tampilkan semua data
              if (filter.isEmpty) return items;
              
              // Jika ada teks yang diketik, saring daftar secara real-time
              return items.where((element) {
                return itemAsString(element)
                    .toLowerCase()
                    .contains(filter.toLowerCase());
              }).toList();
            },
            
            itemAsString: itemAsString,
            compareFn: compareFn,
            
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Ketik untuk mencari...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            
            onSaved: onChanged,
            validator: (val) => val == null ? 'Wajib dipilih' : null,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            tooltip: 'Tambah Data Baru',
            onPressed: onAddPressed,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftState = ref.watch(transaksiDraftProvider);
    
    final barangList = ref.watch(barangControllerProvider).valueOrNull ?? [];
    final mobilList = ref.watch(mobilControllerProvider).valueOrNull ?? [];
    final tokoList = ref.watch(tokoControllerProvider).valueOrNull ?? [];

    final filteredBarang = _selectedKategoriBarang == null 
        ? barangList 
        : barangList.where((b) => b.kategori == _selectedKategoriBarang).toList();
        
    final filteredMobil = _selectedKategoriMobil == null 
        ? mobilList 
        : mobilList.where((m) => m.kategori == _selectedKategoriMobil).toList();

    if (draftState.isLoading || _isSubmitting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Form Pencatatan (Draft #${draftState.idPencatatan})')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- FASE 1: FORM INPUT RENCANA ---
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formItemKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('1. Tambah Rencana Kebutuhan Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(),
                    
                    DropdownButtonFormField<BarangKategori>(
                      initialValue: _selectedKategoriBarang,
                      decoration: const InputDecoration(labelText: 'Filter Kategori Barang', isDense: true, border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<BarangKategori>(value: null, child: Text('Semua Kategori')),
                        ...BarangKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedKategoriBarang = v;
                        _selectedBarang = null; // Reset saat kategori diubah
                      }),
                    ),
                    const SizedBox(height: 16),

                    // IMPLEMENTASI DROPDOWN SEARCH BARANG
                    _buildSearchableDropdownWithShortcut<BarangModel>(
                      label: 'Cari / Pilih Barang',
                      selectedItem: _selectedBarang,
                      items: filteredBarang,
                      itemAsString: (b) => '${b.namaBarang} (${b.kategori?.label ?? "Umum"})',
                      compareFn: (a, b) => a.idBarang == b.idBarang,
                      onChanged: (v) => setState(() => _selectedBarang = v),
                      onAddPressed: () => _showAddBarangShortcut(context),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<MobilKategori>(
                      initialValue: _selectedKategoriMobil,
                      decoration: const InputDecoration(labelText: 'Filter Kategori Mobil', isDense: true, border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<MobilKategori>(value: null, child: Text('Semua Kategori')),
                        ...MobilKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedKategoriMobil = v;
                        _selectedMobil = null; 
                      }),
                    ),
                    const SizedBox(height: 12),

                    // IMPLEMENTASI DROPDOWN SEARCH MOBIL
                    _buildSearchableDropdownWithShortcut<MobilModel>(
                      label: 'Cari / Pilih Alokasi Mobil',
                      selectedItem: _selectedMobil,
                      items: filteredMobil,
                      itemAsString: (m) => '${m.noPlat} (${m.kategori?.label ?? "-"})',
                      compareFn: (a, b) => a.idMobil == b.idMobil,
                      onChanged: (v) => setState(() => _selectedMobil = v),
                      onAddPressed: () => _showAddMobilShortcut(context),
                    ),
                    const SizedBox(height: 16),

                    // IMPLEMENTASI DROPDOWN SEARCH TOKO
                    _buildSearchableDropdownWithShortcut<TokoModel>(
                      label: 'Cari / Pilih Toko Tujuan',
                      selectedItem: _selectedToko,
                      items: tokoList,
                      itemAsString: (t) => t.namaToko,
                      compareFn: (a, b) => a.idToko == b.idToko,
                      onChanged: (v) => setState(() => _selectedToko = v),
                      onAddPressed: () => _showAddTokoShortcut(context),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                            validator: (v) => v!.isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _hargaEstimasiCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Harga Estimasi (Rp)', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Validasi null checks langsung menggunakan Object
                        if (_formItemKey.currentState!.validate() && _selectedBarang != null && _selectedMobil != null && _selectedToko != null) {
                          ref.read(transaksiDraftProvider.notifier).tambahItemKeDraft(
                                idBarang: int.parse(_selectedBarang!.idBarang!),
                                idMobil: int.parse(_selectedMobil!.idMobil!),
                                idToko: int.parse(_selectedToko!.idToko!),
                                qty: int.parse(_qtyCtrl.text),
                                hargaEstimasi: double.tryParse(_hargaEstimasiCtrl.text) ?? 0,
                              );
                          _qtyCtrl.clear();
                          _hargaEstimasiCtrl.clear();
                          setState(() {
                            _selectedBarang = null;
                            _selectedMobil = null;
                            _selectedToko = null;
                          });
                        } else if (_selectedBarang == null || _selectedMobil == null || _selectedToko == null) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Barang, Mobil, dan Toko!'), backgroundColor: Colors.orange));
                        }
                      },
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Masukkan ke Database Draft'),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- FASE 2: DAFTAR EKSEKUSI DI LAPANGAN ---
          const Text('2. Daftar Belanja & Pengisian Riil Lapangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: draftState.items.length,
            itemBuilder: (ctx, i) {
              final item = draftState.items[i];
              final int idDetail = item['id_detail_pencatatan'];

              if (!_hargaRiilControllers.containsKey(idDetail)) {
                _hargaRiilControllers[idDetail] = TextEditingController(
                  text: item['harga_pembelian_barang'].toString() == '0.0' ? '' : item['harga_pembelian_barang'].toString(),
                );
                _statusPembayaranMap[idDetail] = item['status'] ?? 'SELESAI';
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['barang']?['nama_barang']} (${item['barang']?['kategori'] ?? "-"})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => ref.read(transaksiDraftProvider.notifier).hapusItemDariDraft(idDetail),
                          )
                        ],
                      ),
                      Text('Mobil: ${item['mobil']?['no_plat']} | Toko: ${item['toko']?['nama_toko']}'),
                      Text('Jumlah Dibeli: ${item['qty']} unit', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                      const Divider(),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _hargaRiilControllers[idDetail],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Harga Bayar Riil (Rp)', isDense: true, filled: true, fillColor: Colors.white),
                              onChanged: (value) => setState(() {}), 
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _statusPembayaranMap[idDetail],
                              decoration: const InputDecoration(labelText: 'Metode', isDense: true, filled: true, fillColor: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'SELESAI', child: Text('CASH')),
                                DropdownMenuItem(value: 'PENDING', child: Text('HUTANG')),
                              ],
                              onChanged: (v) => setState(() => _statusPembayaranMap[idDetail] = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
                            onPressed: () => _pickKwitansiPerItem(idDetail),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: Text(_kwitansiBytesMap.containsKey(idDetail) ? 'Ubah Foto Kwitansi' : 'Foto Kwitansi Riil'),
                          ),
                          if (_kwitansiBytesMap.containsKey(idDetail))
                            const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), Text(' OK', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])
                          else
                            const Text('*Wajib Diupload', style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          if (draftState.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Belum ada item rencana belanja di draft ini.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
            ),

          const Divider(thickness: 2, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ESTIMASI GRAND TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                AppFormatters.rupiah(_hitungGrandTotal(draftState.items)),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: draftState.items.isEmpty ? null : () => _eksekusiSelesai(draftState.idPencatatan!, draftState.items),
            child: const Text('SELESAIKAN & SIMPAN SEMUA TRANSAKSI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================= MODAL SHORTCUTS TETAP SAMA ================= //

  void _showAddBarangShortcut(BuildContext context) {
    final namaCtrl = TextEditingController();
    BarangKategori? shortcutSelectedKategori; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: const Text('Tambah Barang Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder()), autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<BarangKategori>(
                initialValue: shortcutSelectedKategori,
                decoration: const InputDecoration(labelText: 'Kategori Barang', border: OutlineInputBorder()),
                items: BarangKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
                onChanged: (v) => setStateModal(() => shortcutSelectedKategori = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (namaCtrl.text.isNotEmpty && shortcutSelectedKategori != null) {
                  final newBarang = BarangModel(
                    namaBarang: namaCtrl.text.trim(), 
                    kategori: shortcutSelectedKategori,
                  );
                  await ref.read(barangControllerProvider.notifier).addBarang(newBarang);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMobilShortcut(BuildContext context) {
    final platCtrl = TextEditingController();
    final tahunCtrl = TextEditingController();
    MobilKategori? selectedCat;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: const Text('Tambah Mobil Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: platCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'No Plat', border: OutlineInputBorder()), autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<MobilKategori>(
                initialValue: selectedCat,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: MobilKategori.values.map((k) => DropdownMenuItem(value: k, child: Text(k.label))).toList(),
                onChanged: (v) => setStateModal(() => selectedCat = v),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: tahunCtrl, decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder()), autofocus: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (platCtrl.text.isNotEmpty && selectedCat != null && tahunCtrl.text.isNotEmpty) {
                  final newMobil = MobilModel(noPlat: platCtrl.text.trim().toUpperCase(), kategori: selectedCat, tahun: int.parse(tahunCtrl.text));
                  await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTokoShortcut(BuildContext context) {
    final namaCtrl = TextEditingController();
    final telponCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Toko Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: namaCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama Toko', border: OutlineInputBorder()), autofocus: true),
            const SizedBox(height: 12),
            TextFormField(controller: telponCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No Telp', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: alamatCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.isNotEmpty && telponCtrl.text.isNotEmpty && alamatCtrl.text.isNotEmpty) {
                final newToko = TokoModel(
                  namaToko: namaCtrl.text.trim(),
                  noTelp: telponCtrl.text.trim(),
                  alamat: alamatCtrl.text.trim(),
                );
                await ref.read(tokoControllerProvider.notifier).addToko(newToko);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}