import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

import '../../data/models/barang_model.dart';
import '../../data/models/mobil_model.dart';
import '../../data/models/toko_model.dart';
import '../../data/models/kategori_model.dart';
import '../../data/repositories/transaksi_repository.dart';
import '../../data/repositories/barang_repository.dart';
import '../../domain/providers/barang_provider.dart';
import '../../domain/providers/mobil_provider.dart';
import '../../domain/providers/toko_provider.dart';
import '../../domain/providers/kategori_provider.dart';
import '../../domain/providers/transaksi_draft_provider.dart';
import '../../core/utils/formatters.dart';

class FormPencatatanScreen extends ConsumerStatefulWidget {
  const FormPencatatanScreen({super.key});

  @override
  ConsumerState<FormPencatatanScreen> createState() => _FormPencatatanScreenState();
}

class _FormPencatatanScreenState extends ConsumerState<FormPencatatanScreen> {
  final _formItemKey = GlobalKey<FormState>();

  // ==========================================
  // STATE FILTER & MASTER DATA
  // ==========================================
  KategoriModel? _selectedKategoriMobil;
  MobilModel? _selectedMobil;
  
  KategoriModel? _selectedKategoriBarang;
  BarangModel? _selectedBarang;
  
  TokoModel? _selectedToko;
  
  // Data Barang yang ditarik dari DB berdasarkan Mobil terpilih
  List<BarangModel> _barangSesuaiMobilList = [];
  bool _isLoadingBarang = false;
  
  // Controllers Input Rencana Belanja
  final _qtyCtrl = TextEditingController();
  final _hargaEstimasiCtrl = TextEditingController();

  // Map untuk State Realisasi Lapangan
  final Map<int, TextEditingController> _hargaRiilControllers = {};
  final Map<int, String> _statusPembayaranMap = {};
  final Map<int, DateTime?> _jatuhTempoMap = {}; 
  final Map<int, Uint8List> _kwitansiBytesMap = {};
  final Map<int, String> _kwitansiNameMap = {};
  final Map<int, int> _kwitansiRefMap = {};

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

  // Fetching Barang yang Terkoneksi ke Mobil yang Dipilih
  Future<void> _fetchBarangSesuaiMobil(int idMobil) async {
    setState(() {
      _isLoadingBarang = true;
      _selectedKategoriBarang = null; // Reset filter kategori barang
      _selectedBarang = null; // Reset barang terpilih
    });
    
    try {
      final repo = ref.read(barangRepositoryProvider);
      final hasil = await repo.getBarangSesuaiMobil(idMobil);
      setState(() {
        _barangSesuaiMobilList = hasil;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memfilter barang: $e')));
      }
    } finally {
      setState(() {
        _isLoadingBarang = false;
      });
    }
  }

  // ==========================================
  // LOGIKA GAMBAR & EDIT
  // ==========================================
  void _showImageSourceOptions(BuildContext context, int idDetail) {
    final existingKeys = _kwitansiBytesMap.keys.where((k) => k != idDetail).toList();
    final hasPreviousImage = existingKeys.isNotEmpty;
    final primaryColor = const Color(0xFF1E3A5F);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(alignment: Alignment.centerLeft, child: Text('Upload Kwitansi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: Icon(Icons.camera_alt, color: Colors.blue.shade600)),
                title: const Text('Buka Kamera', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(sheetContext); _pickImage(idDetail, ImageSource.camera); },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: Icon(Icons.photo_library, color: Colors.green.shade600)),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(sheetContext); _pickImage(idDetail, ImageSource.gallery); },
              ),
              if (hasPreviousImage) ...[
                const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider()),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryColor.withAlpha(26), shape: BoxShape.circle), child: Icon(Icons.file_copy_rounded, color: primaryColor)),
                  title: const Text('Gunakan Kwitansi Sebelumnya', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Menyalin referensi struk dari item di atas'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      final prevKey = existingKeys.last;
                      _kwitansiBytesMap[idDetail] = _kwitansiBytesMap[prevKey]!;
                      _kwitansiNameMap[idDetail] = _kwitansiNameMap[prevKey]!;
                      _kwitansiRefMap[idDetail] = _kwitansiRefMap[prevKey]!; 
                    });
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Referensi Kwitansi ditambahkan!'), backgroundColor: primaryColor));
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(int idDetail, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _kwitansiBytesMap[idDetail] = bytes;
          _kwitansiNameMap[idDetail] = image.name;
          _kwitansiRefMap[idDetail] = idDetail; 
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pilihTanggalJatuhTempo(BuildContext context, int idDetail) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _jatuhTempoMap[idDetail] ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _jatuhTempoMap[idDetail]) {
      setState(() {
        _jatuhTempoMap[idDetail] = picked;
      });
    }
  }

  void _editQtyDraft(BuildContext context, int idDetail, int currentQty, String namaBarang) {
    final qtyEditCtrl = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Qty: $namaBarang', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: qtyEditCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah Baru', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final newQty = int.tryParse(qtyEditCtrl.text) ?? currentQty;
              if (newQty > 0) {
                ref.read(transaksiDraftProvider.notifier).updateQtyItemDraft(idDetail, newQty);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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
      final statusPembayaran = _statusPembayaranMap[idDetail] ?? 'SELESAI';
      
      if (hargaInput <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal! Harga riil item "${item['barang']['nama_barang']}" tidak boleh 0.'), backgroundColor: Colors.redAccent));
        return; 
      }
      if (!_kwitansiBytesMap.containsKey(idDetail)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal! Kwitansi untuk item "${item['barang']['nama_barang']}" belum diupload.'), backgroundColor: Colors.red.shade600));
        return; 
      }
      if (statusPembayaran == 'PENDING' && _jatuhTempoMap[idDetail] == null) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilih Tanggal Jatuh Tempo untuk hutang barang "${item['barang']['nama_barang']}".'), backgroundColor: Colors.orange.shade800));
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
        final tglJatuhTempo = _jatuhTempoMap[idDetail];
        
        final refId = _kwitansiRefMap[idDetail] ?? idDetail;
        final isMaster = refId == idDetail;

        finalDataPayload.add({
          'id_detail_pencatatan': idDetail,
          'harga_pembelian_barang': hargaInput,
          'status': statusInput,
          'tgl_jatuh_tempo': statusInput == 'PENDING' && tglJatuhTempo != null ? tglJatuhTempo.toIso8601String() : null,
          'kwitansi_ref_id': refId,
          'image_bytes': isMaster ? _kwitansiBytesMap[idDetail] : null, 
          'image_name': isMaster ? _kwitansiNameMap[idDetail] : null,
        });
      }

      final grandTotal = _hitungGrandTotal(items);

      await ref.read(transaksiRepositoryProvider).finalisasiTransaksi(
            idPencatatan: idDraft,
            grandTotal: grandTotal,
            finalItemsData: finalDataPayload,
          );
      
      ref.invalidate(transaksiDraftProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Sukses Disimpan ke Riwayat! Stok otomatis diperbarui.'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ==========================================
  // WIDGET UI UTAMA
  // ==========================================
  Widget _buildSearchableDropdownWithShortcut<T>({
    required String label,
    required T? selectedItem,
    required List<T> items,
    required String Function(T) itemAsString,
    required bool Function(T, T) compareFn,
    required Function(T?) onChanged,
    VoidCallback? onAddPressed,
    bool isLoading = false,
    String? hintText,
  }) {
    final primaryColor = const Color(0xFF1E3A5F);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownSearch<T>(
            selectedItem: selectedItem,
            items: (String filter, LoadProps? loadProps) {
              if (filter.isEmpty) return items;
              return items.where((element) => itemAsString(element).toLowerCase().contains(filter.toLowerCase())).toList();
            },
            itemAsString: itemAsString,
            compareFn: compareFn,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              emptyBuilder: (context, searchEntry) => Center(child: Text(hintText ?? 'Data tidak ditemukan', style: const TextStyle(color: Colors.grey))),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Ketik untuk mencari...',
                  filled: true, fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
              menuProps: const MenuProps(elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
            ),
            decoratorProps: DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true, fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: isLoading ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)) : null,
              ),
            ),
            onSelected: onChanged,
            validator: (val) => val == null ? 'Wajib dipilih' : null,
          ),
        ),
        if (onAddPressed != null) ...[
          const SizedBox(width: 12),
          InkWell(
            onTap: onAddPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 52, width: 52,
              decoration: BoxDecoration(color: primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryColor.withAlpha(50))),
              child: Icon(Icons.add, color: primaryColor, size: 24),
            ),
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final draftState = ref.watch(transaksiDraftProvider);
    final primaryColor = const Color(0xFF1E3A5F);

    if (draftState.isLoading || _isSubmitting) {
      return Scaffold(backgroundColor: Colors.grey.shade50, body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    // LIST UNTUK MASTER DATA
    final allMobil = ref.watch(mobilControllerProvider).valueOrNull ?? [];
    final tokoList = ref.watch(tokoControllerProvider).valueOrNull ?? [];
    
    // LIST UNTUK FILTER (Data yang tampil di dropdown bergantung pada pilihan Kategori)
    final mobilTampil = _selectedKategoriMobil == null 
        ? allMobil 
        : allMobil.where((m) => m.idKategori == _selectedKategoriMobil!.idKategori).toList();
        
    final barangTampil = _selectedKategoriBarang == null 
        ? _barangSesuaiMobilList 
        : _barangSesuaiMobilList.where((b) => b.idKategori == _selectedKategoriBarang!.idKategori).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      bottomNavigationBar: _buildBottomNav(draftState, primaryColor),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            elevation: 0, backgroundColor: primaryColor, foregroundColor: Colors.white, pinned: true, expandedHeight: 120,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(32))),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Form Pencatatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  Text('Draft #${draftState.idPencatatan}', style: TextStyle(fontSize: 12, color: const Color(0xFF1E3A5F).withAlpha(40), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(padding: EdgeInsets.only(bottom: 12, left: 4), child: Text('1. Rencana Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))]),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formItemKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // ================= ALUR MOBIL =================
                          // 1. Pilih Kategori Mobil
                          Consumer(builder: (ctx, ref, _) {
                            final katMobil = ref.watch(kategoriMobilProvider).valueOrNull ?? [];
                            return DropdownButtonFormField<KategoriModel>(
                              value: _selectedKategoriMobil,
                              decoration: InputDecoration(labelText: '1. Filter Kategori Mobil (Opsional)', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              items: [
                                const DropdownMenuItem<KategoriModel>(value: null, child: Text('Semua Kategori Mobil')),
                                ...katMobil.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori)))
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _selectedKategoriMobil = v;
                                  _selectedMobil = null; // Reset mobil karena kategori berubah
                                  _barangSesuaiMobilList.clear(); // Bersihkan barang lama
                                  _selectedBarang = null;
                                  _selectedKategoriBarang = null;
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 16),

                          // 2. Pilih Mobil (Muncul sesuai filter kategori)
                          _buildSearchableDropdownWithShortcut<MobilModel>(
                            label: '2. Pilih Mobil Alokasi',
                            selectedItem: _selectedMobil,
                            items: mobilTampil,
                            itemAsString: (m) => '${m.noPlat} (${m.kategori?.namaKategori ?? "-"})',
                            compareFn: (a, b) => a.idMobil == b.idMobil,
                            onChanged: (v) {
                               setState(() => _selectedMobil = v);
                               if (v != null && v.idMobil != null) {
                                 _fetchBarangSesuaiMobil(v.idMobil!); // Tembak DB untuk ambil barangnya mobil ini
                               }
                            },
                            onAddPressed: () => _showAddMobilShortcut(context),
                          ),
                          
                          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(thickness: 1.5)),

                          // ================= ALUR BARANG =================
                          // 3. Pilih Kategori Barang
                          Consumer(builder: (ctx, ref, _) {
                            final katBarang = ref.watch(kategoriBarangProvider).valueOrNull ?? [];
                            return DropdownButtonFormField<KategoriModel>(
                              value: _selectedKategoriBarang,
                              decoration: InputDecoration(labelText: '3. Filter Kategori Barang (Opsional)', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              items: [
                                const DropdownMenuItem<KategoriModel>(value: null, child: Text('Semua Kategori Barang')),
                                ...katBarang.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori)))
                              ],
                              onChanged: _selectedMobil == null ? null : (v) { // Nonaktif jika mobil belum dipilih
                                setState(() {
                                  _selectedKategoriBarang = v;
                                  _selectedBarang = null; // Reset barang terpilih
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 16),

                          // 4. Pilih Barang (Muncul sesuai mobil DAN filter kategori barang)
                          _buildSearchableDropdownWithShortcut<BarangModel>(
                            label: '4. Pilih Barang',
                            hintText: _selectedMobil == null ? 'Pilih mobil terlebih dahulu' : 'Data barang tidak ditemukan',
                            selectedItem: _selectedBarang,
                            items: barangTampil,
                            itemAsString: (b) => '${b.namaBarang} (Stok: ${b.stock})',
                            compareFn: (a, b) => a.idBarang == b.idBarang,
                            isLoading: _isLoadingBarang,
                            onChanged: (v) => setState(() => _selectedBarang = v),
                            onAddPressed: () => _showAddBarangShortcut(context),
                          ),
                          
                          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(thickness: 1.5)),

                          // ================= LAINNYA =================
                          // 5. Pilih Toko
                          _buildSearchableDropdownWithShortcut<TokoModel>(
                            label: '5. Pilih Toko Tujuan',
                            selectedItem: _selectedToko,
                            items: tokoList,
                            itemAsString: (t) => t.namaToko,
                            compareFn: (a, b) => a.idToko == b.idToko,
                            onChanged: (v) => setState(() => _selectedToko = v),
                            onAddPressed: () => _showAddTokoShortcut(context),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _qtyCtrl, keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: 'Qty', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                  validator: (v) => v!.isEmpty ? 'Wajib' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _hargaEstimasiCtrl, keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: 'Harga Estimasi (Rp)', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          FilledButton.icon(
                            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () async {
                              if (_formItemKey.currentState!.validate() && _selectedBarang != null && _selectedMobil != null && _selectedToko != null) {
                                try {
                                  await ref.read(transaksiDraftProvider.notifier).tambahItemKeDraft(
                                        idBarang: int.parse(_selectedBarang!.idBarang.toString()),
                                        idMobil: int.parse(_selectedMobil!.idMobil.toString()),
                                        idToko: int.parse(_selectedToko!.idToko.toString()),
                                        qty: int.parse(_qtyCtrl.text),
                                        hargaEstimasi: double.tryParse(_hargaEstimasiCtrl.text) ?? 0,
                                      );
                                  
                                  _qtyCtrl.clear();
                                  _hargaEstimasiCtrl.clear();
                                  setState(() {
                                    _selectedBarang = null;
                                    // Sengaja tidak mereset _selectedMobil agar bisa input banyak barang untuk 1 truk sekaligus
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal Masuk Draft:\n${e.toString().replaceAll('Exception: ', '')}'), 
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    )
                                  );
                                }
                              } else if (_selectedBarang == null || _selectedMobil == null || _selectedToko == null) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Mobil, Barang, dan Toko!'), backgroundColor: Colors.orange));
                              }
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 20),
                            label: const Text('Masukan Ke Daftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Padding(padding: EdgeInsets.only(bottom: 12, left: 4), child: Text('2. Realisasi Lapangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                  
                  if (draftState.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
                      child: Column(children: [Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400), const SizedBox(height: 12), Text('Daftar belanja masih kosong', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500))]),
                    ),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final item = draftState.items[i];
                  final int idDetail = item['id_detail_pencatatan'];
                  final int currentQty = item['qty'] ?? 1;
                  final String namaBarang = item['barang']?['nama_barang'] ?? 'Unknown';

                  if (!_hargaRiilControllers.containsKey(idDetail)) {
                    _hargaRiilControllers[idDetail] = TextEditingController(text: item['harga_pembelian_barang'].toString() == '0.0' ? '' : item['harga_pembelian_barang'].toString());
                    _statusPembayaranMap[idDetail] = item['status'] ?? 'SELESAI';
                  }
                  
                  final isHutang = _statusPembayaranMap[idDetail] == 'PENDING';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))]),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(namaBarang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => _editQtyDraft(context, idDetail, currentQty, namaBarang),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit, color: Colors.blue.shade600, size: 20)),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => ref.read(transaksiDraftProvider.notifier).hapusItemDariDraft(idDetail),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20)),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.directions_car, size: 16, color: primaryColor), const SizedBox(width: 6),
                              Text('${item['mobil']?['no_plat']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 16),
                              Icon(Icons.store, size: 16, color: primaryColor), const SizedBox(width: 6),
                              Text('${item['toko']?['nama_toko']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text('Qty: $currentQty unit', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13))),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, thickness: 1)),
                          
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _hargaRiilControllers[idDetail], keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: 'Harga Riil (Rp)', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                                  onChanged: (value) => setState(() {}), 
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _statusPembayaranMap[idDetail],
                                  decoration: InputDecoration(labelText: 'Pembayaran', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                                  items: const [
                                    DropdownMenuItem(value: 'SELESAI', child: Text('CASH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green))),
                                    DropdownMenuItem(value: 'PENDING', child: Text('HUTANG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange))),
                                  ],
                                  onChanged: (v) => setState(() => _statusPembayaranMap[idDetail] = v!),
                                ),
                              ),
                            ],
                          ),
                          
                          if (isHutang) ...[
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _pilihTanggalJatuhTempo(context, idDetail),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_month_rounded, color: Colors.orange.shade800, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Tanggal Jatuh Tempo', style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                                          Text(
                                            _jatuhTempoMap[idDetail] != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(_jatuhTempoMap[idDetail]!) : 'Pilih Tanggal Pelunasan',
                                            style: TextStyle(fontSize: 14, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_drop_down, color: Colors.orange.shade800),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _kwitansiBytesMap.containsKey(idDetail) ? Colors.green.shade700 : primaryColor,
                                    side: BorderSide(color: _kwitansiBytesMap.containsKey(idDetail) ? Colors.green.shade400 : primaryColor.withAlpha(100), width: 1.5),
                                    backgroundColor: _kwitansiBytesMap.containsKey(idDetail) ? Colors.green.shade50 : Colors.transparent,
                                    minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => _showImageSourceOptions(context, idDetail),
                                  icon: Icon(_kwitansiBytesMap.containsKey(idDetail) ? Icons.check_circle : Icons.camera_alt, size: 20),
                                  label: Text(_kwitansiBytesMap.containsKey(idDetail) ? 'Kwitansi Terunggah' : 'Upload Kwitansi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              if (!_kwitansiBytesMap.containsKey(idDetail)) const Padding(padding: EdgeInsets.only(left: 12), child: Text('*Wajib', style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
                childCount: draftState.items.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(DraftState draftState, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimasi Grand Total', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                Text(AppFormatters.rupiah(_hitungGrandTotal(draftState.items)), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: draftState.items.isEmpty ? null : () => _eksekusiSelesai(draftState.idPencatatan!, draftState.items),
              child: const Text('SIMPAN & SELESAIKAN TRANSAKSI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SHORTCUT MODALS (MENGGUNAKAN RELASI ID KATEGORI INT DATABASE BARU)
  // ============================================================================
  void _showAddBarangShortcut(BuildContext context) {
    final namaCtrl = TextEditingController();
    KategoriModel? shortcutSelectedKategori; 
    final primaryColor = const Color(0xFF1E3A5F);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Tambah Barang Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: namaCtrl, decoration: InputDecoration(labelText: 'Nama Barang', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), autofocus: true),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  return ref.watch(kategoriBarangProvider).when(
                    data: (kategoriList) => DropdownButtonFormField<KategoriModel>(
                      value: shortcutSelectedKategori,
                      decoration: InputDecoration(labelText: 'Kategori Barang', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori))).toList(),
                      onChanged: (v) => setStateModal(() => shortcutSelectedKategori = v),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Gagal muat kategori'),
                  );
                }
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (namaCtrl.text.isNotEmpty && shortcutSelectedKategori != null) {
                  final newBarang = BarangModel(
                    namaBarang: namaCtrl.text.trim(), 
                    idKategori: shortcutSelectedKategori!.idKategori
                  );
                  await ref.read(barangControllerProvider.notifier).addBarang(newBarang);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMobilShortcut(BuildContext context) {
    final platCtrl = TextEditingController();
    final tahunCtrl = TextEditingController();
    KategoriModel? selectedCat;
    final primaryColor = const Color(0xFF1E3A5F);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Tambah Mobil Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: platCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: 'No Plat', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), autofocus: true),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  return ref.watch(kategoriMobilProvider).when(
                    data: (kategoriList) => DropdownButtonFormField<KategoriModel>(
                      value: selectedCat,
                      decoration: InputDecoration(labelText: 'Kategori Mobil', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori))).toList(),
                      onChanged: (v) => setStateModal(() => selectedCat = v),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Gagal muat kategori'),
                  );
                }
              ),
              const SizedBox(height: 16),
              TextFormField(controller: tahunCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Tahun Armada', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (platCtrl.text.isNotEmpty && selectedCat != null && tahunCtrl.text.isNotEmpty) {
                  final newMobil = MobilModel(
                    noPlat: platCtrl.text.trim().toUpperCase(), 
                    idKategori: selectedCat!.idKategori, 
                    tahun: int.parse(tahunCtrl.text)
                  );
                  await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTokoShortcut(BuildContext context) {
    // [Isi fungsi _showAddTokoShortcut sama persis seperti sebelumnya]
    final namaCtrl = TextEditingController();
    final telponCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final primaryColor = const Color(0xFF1E3A5F);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tambah Toko Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: namaCtrl, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'Nama Toko', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), autofocus: true),
            const SizedBox(height: 16),
            TextFormField(controller: telponCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'No Telp', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            TextFormField(controller: alamatCtrl, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: 'Alamat', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (namaCtrl.text.isNotEmpty && telponCtrl.text.isNotEmpty && alamatCtrl.text.isNotEmpty) {
                final newToko = TokoModel(namaToko: namaCtrl.text.trim(), noTelp: telponCtrl.text.trim(), alamat: alamatCtrl.text.trim());
                await ref.read(tokoControllerProvider.notifier).addToko(newToko);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}