import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/barang_model.dart';
import '../../domain/providers/barang_provider.dart';

class BarangScreen extends ConsumerStatefulWidget {
  const BarangScreen({super.key});

  @override
  ConsumerState<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends ConsumerState<BarangScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final barangState = ref.watch(barangControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text('Kelola Data Barang')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: barangState.when(
              data: _buildBarangList,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Terjadi kesalahan: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormBottomSheet(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Cari nama barang atau kategori...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildBarangList(List<BarangModel> listBarang) {
    final filteredList = listBarang.where((barang) {
      final query = _searchQuery.toLowerCase();
      final namaMatch = barang.namaBarang.toLowerCase().contains(query);
      final kategoriMatch = barang.kategori?.label.toLowerCase().contains(query) ?? false;
      return namaMatch || kategoriMatch;
    }).toList();

    if (listBarang.isEmpty) {
      return const Center(child: Text('Belum ada data barang.'));
    }

    if (filteredList.isEmpty) {
      return const Center(child: Text('Barang tidak ditemukan.'));
    }

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        return _BarangListItem(barang: filteredList[index]);
      },
    );
  }
}

class _BarangListItem extends ConsumerWidget {
  final BarangModel barang;

  const _BarangListItem({required this.barang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            barang.namaBarang.isNotEmpty ? barang.namaBarang[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        title: Text(
          barang.namaBarang,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Kategori: ${barang.kategori?.label ?? 'Umum'} | Stok: ${barang.stock}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showFormBottomSheet(context, barang: barang),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref, barang),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BarangModel barang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Yakin ingin menghapus ${barang.namaBarang}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(barangControllerProvider.notifier).deleteBarang(barang.idBarang!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showFormBottomSheet(BuildContext context, {BarangModel? barang}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _BarangFormSheet(barang: barang),
  );
}

class _BarangFormSheet extends ConsumerStatefulWidget {
  final BarangModel? barang;

  const _BarangFormSheet({this.barang});

  @override
  ConsumerState<_BarangFormSheet> createState() => _BarangFormSheetState();
}

class _BarangFormSheetState extends ConsumerState<_BarangFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _stockCtrl;
  BarangKategori? _selectedKategori;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.barang?.namaBarang);
    _stockCtrl = TextEditingController(text: widget.barang?.stock.toString() ?? '0');
    _selectedKategori = widget.barang?.kategori;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newBarang = BarangModel(
      idBarang: widget.barang?.idBarang,
      namaBarang: _namaCtrl.text.trim(),
      kategori: _selectedKategori,
      stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
    );

    try {
      if (widget.barang != null) {
        await ref.read(barangControllerProvider.notifier).updateBarang(newBarang);
      } else {
        await ref.read(barangControllerProvider.notifier).addBarang(newBarang);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar(e.toString());
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String errorMessage) {
    final sanitizedMessage = errorMessage.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sanitizedMessage), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.barang != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? 'Edit Barang' : 'Tambah Barang Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _namaCtrl,
              label: 'Nama Barang',
              textCapitalization: TextCapitalization.words,
              validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _stockCtrl,
              label: 'Stok Awal',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(isEdit),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<BarangKategori>(
      value: _selectedKategori,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
      ),
      items: BarangKategori.values.map((k) {
        return DropdownMenuItem(
          value: k,
          child: Text(k.label),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() => _selectedKategori = newValue);
      },
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
      ),
      onPressed: _isSubmitting ? null : _submitForm,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
          : Text(
              isEdit ? 'Simpan Perubahan' : 'Simpan Barang',
              style: const TextStyle(color: Colors.white),
            ),
    );
  }
}