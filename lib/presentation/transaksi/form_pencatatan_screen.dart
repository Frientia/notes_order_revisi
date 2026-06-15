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
  
  List<BarangModel> _barangSesuaiMobilList = [];
  bool _isLoadingBarang = false;
  
  final _qtyCtrl = TextEditingController();
  final _hargaEstimasiCtrl = TextEditingController();

  int? _editingIdDetail;
  bool get _isEditing => _editingIdDetail != null;

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

  Future<void> _fetchBarangSesuaiMobil(int idMobil) async {
    setState(() {
      _isLoadingBarang = true;
      _selectedKategoriBarang = null; 
      _selectedBarang = null; 
    });
    
    try {
      final repo = ref.read(barangRepositoryProvider);
      final hasil = await repo.getBarangSesuaiMobil(idMobil);
      setState(() {
        _barangSesuaiMobilList = hasil;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memfilter barang: $e')));
    } finally {
      setState(() => _isLoadingBarang = false);
    }
  }

 Future<void> _tarikDataKeForm(
  Map<String, dynamic> item,
  List<MobilModel> allMobil,
  List<TokoModel> allToko,
) async {
  final mobilId = item['id_mobil'];
  final tokoId = item['id_toko'];
  final barangId = item['id_barang'];

  setState(() {
    _editingIdDetail = item['id_detail_pencatatan'];

    _qtyCtrl.text = item['qty']?.toString() ?? '';

    _hargaEstimasiCtrl.text =
        item['harga_pembelian_barang'] == null ||
                item['harga_pembelian_barang'].toString() == '0.0'
            ? ''
            : item['harga_pembelian_barang'].toString();

    _selectedMobil = allMobil
        .where((m) => m.idMobil == mobilId)
        .firstOrNull;

    _selectedToko = allToko
        .where((t) => t.idToko.toString() == tokoId.toString())
        .firstOrNull;
  });

  if (_selectedMobil?.idMobil != null) {
    await _fetchBarangSesuaiMobil(_selectedMobil!.idMobil!);

    setState(() {
      _selectedBarang = _barangSesuaiMobilList
          .where((b) => b.idBarang == barangId)
          .firstOrNull;
    });
  }

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Mode Edit Aktif: Silakan ubah data di form atas.',
      ),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 2),
    ),
  );
}

  void _resetForm() {
    setState(() {
      _editingIdDetail = null;
      _qtyCtrl.clear();
      _hargaEstimasiCtrl.clear();
      _selectedKategoriMobil = null;
      _selectedMobil = null;
      _selectedKategoriBarang = null;
      _selectedBarang = null;
      _selectedToko = null;
      _barangSesuaiMobilList.clear();
    });
  }

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

  double _hitungGrandTotal(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      final idDetail = item['id_detail_pencatatan'] as int;
      final inputText = _hargaRiilControllers[idDetail]?.text ?? '';
      final harga = inputText.isNotEmpty ? (double.tryParse(inputText) ?? 0) : (double.tryParse(item['harga_pembelian_barang'].toString()) ?? 0);
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
      
      // 1. Validasi Harga (Mencegah 0 dan Minus)
      if (hargaInput <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠️ Tunggu dulu! Harga riil "${item['barang']['nama_barang']}" tidak boleh 0 atau minus.'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating, // Membuat snackbar melayang
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
        return; 
      }

      // 2. Validasi Kwitansi
      if (!_kwitansiBytesMap.containsKey(idDetail)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📸 Oops! Kwitansi untuk "${item['barang']['nama_barang']}" wajib diupload.'), 
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
        return; 
      }

      // 3. Validasi Tanggal Jatuh Tempo (Khusus Hutang)
      if (statusPembayaran == 'PENDING' && _jatuhTempoMap[idDetail] == null) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('🗓️ Pilih Tanggal Jatuh Tempo untuk hutang "${item['barang']['nama_barang']}".'), 
           backgroundColor: Colors.orange.shade800,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
           margin: const EdgeInsets.all(16),
         ));
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
      ref.invalidate(barangControllerProvider); 

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

  // WIDGET BANTUAN UNTUK LABEL DI LUAR KOTAK AGAR TIDAK NABRAK
  Widget _buildExternalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13)),
    );
  }

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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExternalLabel(label), // LABEL DI LUAR
        Row(
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
                    hintText: 'Pilih...', // Menggunakan hintText bukan labelText
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true, fillColor: Colors.white,
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
        ),
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

    final allMobil = ref.watch(mobilControllerProvider).valueOrNull ?? [];
    final tokoList = ref.watch(tokoControllerProvider).valueOrNull ?? [];
    
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(padding: EdgeInsets.only(bottom: 12, left: 4), child: Text('1. Rencana Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                      if (_editingIdDetail != null)
                        TextButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                          label: const Text('Batal Edit', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _editingIdDetail != null ? Colors.orange.shade50 : Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: _editingIdDetail != null ? Colors.orange.shade300 : Colors.transparent, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))]
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formItemKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          Consumer(builder: (ctx, ref, _) {
                            final katMobil = ref.watch(kategoriMobilProvider).valueOrNull ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildExternalLabel('1. Filter Kategori Mobil (Opsional)'),
                                DropdownButtonFormField<KategoriModel>(
                                  value: _selectedKategoriMobil,
                                  decoration: InputDecoration(
                                    hintText: 'Semua Kategori Mobil',
                                    filled: true, fillColor: Colors.white, 
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                                  ),
                                  items: [
                                    const DropdownMenuItem<KategoriModel>(value: null, child: Text('Semua Kategori Mobil')),
                                    ...katMobil.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori)))
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedKategoriMobil = v;
                                      _selectedMobil = null; 
                                      _barangSesuaiMobilList.clear(); 
                                      _selectedBarang = null;
                                      _selectedKategoriBarang = null;
                                    });
                                  },
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 16),

                          _buildSearchableDropdownWithShortcut<MobilModel>(
                            label: '2. Pilih Mobil Alokasi',
                            selectedItem: _selectedMobil,
                            items: mobilTampil,
                            itemAsString: (m) => '${m.noPlat} (${m.kategori?.namaKategori ?? "-"})',
                            compareFn: (a, b) => a.idMobil == b.idMobil,
                            onChanged: (v) {
                               setState(() => _selectedMobil = v);
                               if (v != null && v.idMobil != null) {
                                 _fetchBarangSesuaiMobil(v.idMobil!); 
                               }
                            },
                            onAddPressed: () => _showAddMobilShortcut(context),
                          ),
                          
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(thickness: 1.5)),

                          Consumer(builder: (ctx, ref, _) {
                            final katBarang = ref.watch(kategoriBarangProvider).valueOrNull ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildExternalLabel('3. Filter Kategori Barang (Opsional)'),
                                DropdownButtonFormField<KategoriModel>(
                                  value: _selectedKategoriBarang,
                                  decoration: InputDecoration(
                                    hintText: 'Semua Kategori Barang',
                                    filled: true, fillColor: Colors.white, 
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                                  ),
                                  items: [
                                    const DropdownMenuItem<KategoriModel>(value: null, child: Text('Semua Kategori Barang')),
                                    ...katBarang.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori)))
                                  ],
                                  onChanged: _selectedMobil == null ? null : (v) { 
                                    setState(() {
                                      _selectedKategoriBarang = v;
                                      _selectedBarang = null; 
                                    });
                                  },
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 16),

                          _buildSearchableDropdownWithShortcut<BarangModel>(
                            label: '4. Pilih Barang',
                            hintText: _selectedMobil == null ? 'Pilih mobil terlebih dahulu' : 'Cari barang...',
                            selectedItem: _selectedBarang,
                            items: barangTampil,
                            itemAsString: (b) => '${b.namaBarang} (Stok: ${b.stock})',
                            compareFn: (a, b) => a.idBarang == b.idBarang,
                            isLoading: _isLoadingBarang,
                            onChanged: (v) => setState(() => _selectedBarang = v),
                            onAddPressed: () => _showAddBarangShortcut(context),
                          ),
                          
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(thickness: 1.5)),

                          _buildSearchableDropdownWithShortcut<TokoModel>(
                            label: '5. Pilih Toko Tujuan',
                            hintText: 'Cari Toko...',
                            selectedItem: _selectedToko,
                            items: tokoList,
                            itemAsString: (t) => t.namaToko,
                            compareFn: (a, b) => a.idToko == b.idToko,
                            onChanged: (v) => setState(() => _selectedToko = v),
                            onAddPressed: () => _showAddTokoShortcut(context),
                          ),
                          const SizedBox(height: 24),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildExternalLabel('Qty'),
                                    TextFormField(
                                      controller: _qtyCtrl, 
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: '1', 
                                        filled: true, 
                                        fillColor: Colors.white, 
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), 
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), 
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Wajib diisi!';
                                        
                                        final qtyInput = int.tryParse(v.trim());
                                        if (qtyInput == null) return 'Harus berupa angka!';
                                        if (qtyInput <= 0) return 'Qty tidak boleh 0 atau minus!';
                                        
                                        if (_selectedBarang != null) {
                                          if (_selectedBarang!.stock <= 0) {
                                            return 'Stok kosong! Tidak bisa dicatat.';
                                          }
                                          if (qtyInput > _selectedBarang!.stock) {
                                            return 'Stok tidak cukup! (Sisa: ${_selectedBarang!.stock})';
                                          }
                                        }
                                        return null; // Lolos sensor
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildExternalLabel('Harga Estimasi (Rp)'),
                                    TextFormField(
                                      controller: _hargaEstimasiCtrl, 
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Misal: 50000', 
                                        filled: true, 
                                        fillColor: Colors.white, 
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), 
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), 
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                                      ),
                                      validator: (v) {
                                        if (v != null && v.trim().isNotEmpty) {
                                          final harga = double.tryParse(v.trim());
                                          if (harga == null) return 'Harus berupa angka!';
                                          if (harga < 0) return 'Harga tidak boleh minus!';
                                        }
                                        return null; // Lolos sensor
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52), 
                              backgroundColor: _editingIdDetail != null ? Colors.orange.shade700 : primaryColor, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            onPressed: () async {
                              if (_formItemKey.currentState!.validate() && _selectedBarang != null && _selectedMobil != null && _selectedToko != null) {
                                try {
                                  if (_editingIdDetail != null) {
                                    await ref.read(transaksiDraftProvider.notifier).hapusItemDariDraft(_editingIdDetail!);
                                    await ref.read(transaksiDraftProvider.notifier).tambahItemKeDraft(
                                      idBarang: int.parse(_selectedBarang!.idBarang.toString()),
                                      idMobil: int.parse(_selectedMobil!.idMobil.toString()),
                                      idToko: int.parse(_selectedToko!.idToko.toString()),
                                      qty: int.parse(_qtyCtrl.text),
                                      hargaEstimasi: double.tryParse(_hargaEstimasiCtrl.text) ?? 0,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item berhasil diperbarui!'), backgroundColor: Colors.green));
                                  } else {
                                    await ref.read(transaksiDraftProvider.notifier).tambahItemKeDraft(
                                      idBarang: int.parse(_selectedBarang!.idBarang.toString()),
                                      idMobil: int.parse(_selectedMobil!.idMobil.toString()),
                                      idToko: int.parse(_selectedToko!.idToko.toString()),
                                      qty: int.parse(_qtyCtrl.text),
                                      hargaEstimasi: double.tryParse(_hargaEstimasiCtrl.text) ?? 0,
                                    );
                                  }
                                  _resetForm(); 
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal Masuk Draft:\n${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red, duration: const Duration(seconds: 4))
                                  );
                                }
                              } else {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Mobil, Barang, dan Toko secara lengkap!'), backgroundColor: Colors.red));
                              }
                            },
                            icon: Icon(_editingIdDetail != null ? Icons.save : Icons.add_shopping_cart, size: 20),
                            label: Text(_editingIdDetail != null ? 'Simpan Perubahan Item' : 'Masukan Ke Daftar Belanja', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isEditing)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Realisasi dikunci sementara. Simpan atau batalkan edit untuk melanjutkan.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
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
                    decoration: BoxDecoration(
                      color: _editingIdDetail == idDetail ? Colors.orange.shade50 : Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(color: _editingIdDetail == idDetail ? Colors.orange.shade300 : Colors.transparent, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 15, offset: const Offset(0, 8))]
                    ),
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
                                    onTap: _isEditing
                                          ? null
                                          : () => _tarikDataKeForm(item, allMobil, tokoList),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.edit, color: Colors.blue.shade600, size: 20)),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _isEditing
                                          ? null
                                          : () => ref
                                                .read(transaksiDraftProvider.notifier)
                                                .hapusItemDariDraft(idDetail),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildExternalLabel('Harga Riil (Rp)'),
                                    TextFormField(
                                      controller: _hargaRiilControllers[idDetail],
                                      keyboardType: TextInputType.number,
                                      readOnly: _isEditing,
                                      enabled: !_isEditing,
                                      decoration: InputDecoration(hintText: 'Isi harga akhir', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                                      onChanged: (value) => setState(() {}), 
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildExternalLabel('Pembayaran'),
                                    DropdownButtonFormField<String>(
                                      value: _statusPembayaranMap[idDetail],
                                      decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                                      items: const [
                                        DropdownMenuItem(value: 'SELESAI', child: Text('CASH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green))),
                                        DropdownMenuItem(value: 'PENDING', child: Text('HUTANG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange))),
                                      ],
                                      onChanged: _isEditing
                                        ? null
                                        : (v) => setState(() {
                                              _statusPembayaranMap[idDetail] = v!;
                                            }),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          if (isHutang) ...[
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: _isEditing ? 0.5 : 1,
                              child: InkWell(
                                onTap: _isEditing
                                    ? null
                                    : () => _pilihTanggalJatuhTempo(context, idDetail),
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
                                              _jatuhTempoMap[idDetail] != null ? DateFormat('dd-MM-yyyy').format(_jatuhTempoMap[idDetail]!) : 'Pilih Tanggal Pelunasan',
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
                                  onPressed: _isEditing
                                    ? null
                                    : () => _showImageSourceOptions(context, idDetail),
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
  // SHORTCUT MODALS (BOTTOM SHEETS)
  // ============================================================================
  void _showAddBarangShortcut(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const _ShortcutBarangFormSheet());
  }

  void _showAddMobilShortcut(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const _ShortcutMobilFormSheet());
  }

  void _showAddTokoShortcut(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => const _ShortcutTokoFormSheet());
  }
}

// ============================================================================
// WIDGET KELAS KHUSUS UNTUK FORM BOTTOM SHEET
// ============================================================================
class _ShortcutBarangFormSheet extends ConsumerStatefulWidget {
  const _ShortcutBarangFormSheet();
  @override
  ConsumerState<_ShortcutBarangFormSheet> createState() => _ShortcutBarangFormSheetState();
}

class _ShortcutBarangFormSheetState extends ConsumerState<_ShortcutBarangFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  
  KategoriModel? _selectedKategori;
  final List<int> _selectedMobilIds = []; 
  bool _isSubmitting = false;

  String _searchMobilQuery = '';
  int? _filterKatMobilDiForm;

  @override
  void dispose() { _namaCtrl.dispose(); _stockCtrl.dispose(); super.dispose(); }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isSubmitting = true);
    final newBarang = BarangModel(namaBarang: _namaCtrl.text.trim(), idKategori: _selectedKategori!.idKategori, stock: int.tryParse(_stockCtrl.text.trim()) ?? 0);
    try {
      await ref.read(barangControllerProvider.notifier).addBarang(newBarang, listIdMobilCocok: _selectedMobilIds);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildExternalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3A5F);
    final height = MediaQuery.of(context).size.height * 0.9; 

    return Container(
      height: height,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 12),
      child: Column(
        children: [
          Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const Text('Tambah Barang Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExternalLabel('Nama Barang'),
                    TextFormField(
                      controller: _namaCtrl, textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(hintText: 'Ketik nama barang', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildExternalLabel('Kategori'),
                    ref.watch(kategoriBarangProvider).when(
                      data: (listKategori) => DropdownButtonFormField<KategoriModel>(
                        value: _selectedKategori,
                        decoration: InputDecoration(hintText: 'Pilih Kategori', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                        items: listKategori.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori))).toList(),
                        onChanged: (val) => setState(() => _selectedKategori = val),
                        validator: (val) => val == null ? 'Pilih kategori' : null,
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 16),
                    _buildExternalLabel('Stok Awal'),
                    TextFormField(
                      controller: _stockCtrl, keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: '0', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('Kecocokan Mobil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            onChanged: (val) => setState(() => _searchMobilQuery = val),
                            decoration: InputDecoration(hintText: 'Cari Plat...', prefixIcon: const Icon(Icons.search, size: 18), contentPadding: const EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: ref.watch(kategoriMobilProvider).when(
                            data: (kategoriList) => DropdownButtonFormField<int?>(
                              value: _filterKatMobilDiForm,
                              decoration: InputDecoration(hintText: 'Semua Mobil', contentPadding: const EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Semua Mobil')),
                                ...kategoriList.map((k) => DropdownMenuItem(value: k.idKategori, child: Text(k.namaKategori, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (val) => setState(() => _filterKatMobilDiForm = val),
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: ref.watch(mobilControllerProvider).when(
                        data: (listMobil) {
                          final filteredMobil = listMobil.where((mobil) {
                            final matchSearch = mobil.noPlat.toLowerCase().contains(_searchMobilQuery.toLowerCase());
                            final matchKat = _filterKatMobilDiForm == null || mobil.idKategori == _filterKatMobilDiForm;
                            return matchSearch && matchKat;
                          }).toList();

                          if (listMobil.isEmpty) return const Center(child: Text('Belum ada data mobil.'));
                          if (filteredMobil.isEmpty) return const Center(child: Text('Mobil tidak ditemukan.'));

                          return ListView.builder(
                            itemCount: filteredMobil.length,
                            itemBuilder: (context, index) {
                              final mobil = filteredMobil[index];
                              final isChecked = _selectedMobilIds.contains(mobil.idMobil);
                              return CheckboxListTile(
                                title: Text(mobil.noPlat, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(mobil.kategori?.namaKategori ?? 'Tanpa Kategori', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                value: isChecked,
                                activeColor: const Color(0xFF1E3A5F),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) _selectedMobilIds.add(mobil.idMobil!);
                                    else _selectedMobilIds.remove(mobil.idMobil);
                                  });
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Center(child: Text('Gagal memuat mobil.')),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Simpan Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutMobilFormSheet extends ConsumerStatefulWidget {
  const _ShortcutMobilFormSheet();
  @override
  ConsumerState<_ShortcutMobilFormSheet> createState() => _ShortcutMobilFormSheetState();
}

class _ShortcutMobilFormSheetState extends ConsumerState<_ShortcutMobilFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _platCtrl = TextEditingController();
  final _tahunCtrl = TextEditingController();
  KategoriModel? _selectedKategori;
  bool _isSubmitting = false;

  @override
  void dispose() { _platCtrl.dispose(); _tahunCtrl.dispose(); super.dispose(); }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedKategori == null) return;
    setState(() => _isSubmitting = true);
    try {
      final newMobil = MobilModel(noPlat: _platCtrl.text.trim().toUpperCase(), idKategori: _selectedKategori!.idKategori, tahun: int.parse(_tahunCtrl.text));
      await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildExternalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3A5F);
    
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const Text('Tambah Mobil Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExternalLabel('No Plat'),
                TextFormField(controller: _platCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'Misal: B 1234 CD', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                const SizedBox(height: 16),
                _buildExternalLabel('Kategori Mobil'),
                ref.watch(kategoriMobilProvider).when(
                  data: (kategoriList) => DropdownButtonFormField<KategoriModel>(
                    value: _selectedKategori, decoration: InputDecoration(hintText: 'Pilih Kategori', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    items: kategoriList.map((k) => DropdownMenuItem(value: k, child: Text(k.namaKategori))).toList(),
                    onChanged: (v) => setState(() => _selectedKategori = v), validator: (v) => v == null ? 'Pilih kategori' : null,
                  ),
                  loading: () => const CircularProgressIndicator(), error: (_, __) => const Text('Gagal muat kategori'),
                ),
                const SizedBox(height: 16),
                _buildExternalLabel('Tahun Armada'),
                TextFormField(controller: _tahunCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Misal: 2020', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _isSubmitting ? null : _submitForm, child: _isSubmitting ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Simpan Mobil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
        ],
      ),
    );
  }
}

class _ShortcutTokoFormSheet extends ConsumerStatefulWidget {
  const _ShortcutTokoFormSheet();
  @override
  ConsumerState<_ShortcutTokoFormSheet> createState() => _ShortcutTokoFormSheetState();
}

class _ShortcutTokoFormSheetState extends ConsumerState<_ShortcutTokoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _telponCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() { _namaCtrl.dispose(); _telponCtrl.dispose(); _alamatCtrl.dispose(); super.dispose(); }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final newToko = TokoModel(namaToko: _namaCtrl.text.trim(), noTelp: _telponCtrl.text.trim(), alamat: _alamatCtrl.text.trim());
      await ref.read(tokoControllerProvider.notifier).addToko(newToko);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildExternalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3A5F);
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const Text('Tambah Toko Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExternalLabel('Nama Toko'),
                TextFormField(controller: _namaCtrl, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: 'Ketik nama toko', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                const SizedBox(height: 16),
                _buildExternalLabel('No Telp (Opsional)'),
                TextFormField(controller: _telponCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: 'Misal: 0812...', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 16),
                _buildExternalLabel('Alamat Lengkap'),
                TextFormField(controller: _alamatCtrl, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: 'Alamat toko...', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _isSubmitting ? null : _submitForm, child: _isSubmitting ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Simpan Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ),
        ],
      ),
    );
  }
}