import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_order/data/models/keranjang_item_model.dart';

import '../../data/repositories/transaksi_repository.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/barang_provider.dart';
import '../../domain/providers/mobil_provider.dart';
import '../../domain/providers/keranjang_provider.dart';
import '../../domain/providers/toko_provider.dart';
import '../../core/utils/formatters.dart'; 

class FormPencatatanScreen extends ConsumerStatefulWidget {
  const FormPencatatanScreen({super.key});

  @override
  ConsumerState<FormPencatatanScreen> createState() => _FormPencatatanScreenState();
}

class _FormPencatatanScreenState extends ConsumerState<FormPencatatanScreen> {
  final _formItemKey = GlobalKey<FormState>();
  
  String? _selectedIdBarang;
  String? _selectedIdMobil;
  String? _selectedIdToko;
  String _statusPembayaranItem = 'SELESAI';
  
  final _qtyCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  
  XFile? _imageKwitansi;
  Uint8List? _imageBytes;
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _hargaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageKwitansi = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  void _tambahKeKeranjang() {
    if (_formItemKey.currentState!.validate()) {
      if (_selectedIdBarang == null || _selectedIdMobil == null || _selectedIdToko == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua field!')));
        return;
      }
      if (_imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload Foto Kwitansi untuk barang ini!')));
        return;
      }

      final barangList = ref.read(barangControllerProvider).value ?? [];
      final mobilList = ref.read(mobilControllerProvider).value ?? [];
      final tokoList = ref.read(tokoControllerProvider).value ?? [];
      
      final barang = barangList.firstWhere((b) => b.idBarang == _selectedIdBarang);
      final mobil = mobilList.firstWhere((m) => m.idMobil == _selectedIdMobil);
      final toko = tokoList.firstWhere((t) => t.idToko == _selectedIdToko);

      final item = KeranjangItem(
        idBarang: barang.idBarang!,
        namaBarang: barang.namaBarang,
        idMobil: mobil.idMobil!,
        noPlatMobil: mobil.noPlat,
        idToko: toko.idToko!,
        namaToko: toko.namaToko,
        qty: int.parse(_qtyCtrl.text),
        hargaPembelian: double.parse(_hargaCtrl.text),
        statusPembayaran: _statusPembayaranItem,
        imageBytes: _imageBytes!,
        imageName: _imageKwitansi!.name,
      );

      ref.read(keranjangProvider.notifier).tambahItem(item);
      
      _qtyCtrl.clear();
      _hargaCtrl.clear();
      setState(() {
        _selectedIdBarang = null;
        _selectedIdMobil = null;
        _selectedIdToko = null;
        _imageKwitansi = null;
        _imageBytes = null;
        _statusPembayaranItem = 'SELESAI';
      });
    }
  }

  Future<void> _simpanTransaksi() async {
    final keranjang = ref.read(keranjangProvider);
    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong!')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final uid = ref.read(authStateProvider).value!.uid;
      final total = ref.read(keranjangProvider.notifier).grandTotal;
      
      await ref.read(transaksiRepositoryProvider).simpanTransaksiMultitoko(
        firebaseUid: uid,
        keranjang: keranjang,
        grandTotal: total,
      );

      if (mounted) {
        ref.read(keranjangProvider.notifier).clearKeranjang();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi Berhasil Disimpan!'), backgroundColor: Colors.green)
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barangState = ref.watch(barangControllerProvider);
    final mobilState = ref.watch(mobilControllerProvider);
    final tokoState = ref.watch(tokoControllerProvider);
    final keranjang = ref.watch(keranjangProvider);
    final grandTotal = ref.watch(keranjangProvider.notifier).grandTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Pembelian Baru')),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    const Text('Input Detail Barang & Kwitansi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      value: _selectedIdBarang,
                      decoration: const InputDecoration(labelText: 'Pilih Barang', isDense: true),
                      items: barangState.valueOrNull?.map((b) => DropdownMenuItem(value: b.idBarang, child: Text(b.namaBarang))).toList(),
                      onChanged: (v) => setState(() => _selectedIdBarang = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedIdMobil,
                      decoration: const InputDecoration(labelText: 'Pilih Mobil (Alokasi)', isDense: true),
                      items: mobilState.valueOrNull?.map((m) => DropdownMenuItem(value: m.idMobil, child: Text(m.noPlat))).toList(),
                      onChanged: (v) => setState(() => _selectedIdMobil = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedIdToko,
                      decoration: const InputDecoration(labelText: 'Pilih Toko', isDense: true),
                      items: tokoState.valueOrNull?.map((t) => DropdownMenuItem(value: t.idToko.toString(), child: Text(t.namaToko))).toList(),
                      onChanged: (v) => setState(() => _selectedIdToko = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                            validator: (v) => v!.isEmpty ? 'Isi' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _hargaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Harga Satuan (Rp)'),
                            validator: (v) => v!.isEmpty ? 'Isi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusPembayaranItem,
                      decoration: const InputDecoration(labelText: 'Status Pembayaran Item', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'SELESAI', child: Text('LUNAS (Cash)')),
                        DropdownMenuItem(value: 'PENDING', child: Text('HUTANG (Kredit)')),
                      ],
                      onChanged: (v) => setState(() => _statusPembayaranItem = v!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Pilih Foto Kwitansi'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _imageBytes == null 
                          ? const Text('Belum ada foto', style: TextStyle(color: Colors.red))
                          : const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _tambahKeKeranjang,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Tambahkan ke Daftar'),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Daftar Pembelian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keranjang.length,
            itemBuilder: (ctx, i) {
              final item = keranjang[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.receipt, color: Colors.purple),
                  title: Text(item.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Plat: ${item.noPlatMobil}\n'
                    '${item.qty} x ${AppFormatters.rupiah(item.hargaPembelian)}\n'
                    'Status: ${item.statusPembayaran == 'SELESAI' ? 'LUNAS' : 'HUTANG'}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppFormatters.rupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      InkWell(
                        onTap: () => ref.read(keranjangProvider.notifier).hapusItem(i),
                        child: const Icon(Icons.delete, color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (keranjang.isEmpty) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Daftar masih kosong, silakan input barang di atas.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          
          const Divider(thickness: 2, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GRAND TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(AppFormatters.rupiah(grandTotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: keranjang.isEmpty ? null : _simpanTransaksi,
            child: const Text('SIMPAN SEMUA TRANSAKSI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}