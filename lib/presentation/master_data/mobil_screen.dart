import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mobil_model.dart';
import '../../domain/providers/mobil_provider.dart';

class MobilScreen extends ConsumerWidget {
  const MobilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobilState = ref.watch(mobilControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Data Mobil')),
      body: mobilState.when(
        data: _buildMobilList,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormBottomSheet(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMobilList(List<MobilModel> listMobil) {
    if (listMobil.isEmpty) {
      return const Center(child: Text('Belum ada data mobil.'));
    }

    return ListView.builder(
      itemCount: listMobil.length,
      itemBuilder: (context, index) {
        return _MobilListItem(mobil: listMobil[index]);
      },
    );
  }
}

class _MobilListItem extends ConsumerWidget {
  final MobilModel mobil;

  const _MobilListItem({required this.mobil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.directions_car, color: Colors.white),
        ),
        title: Text(
          mobil.noPlat,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '${mobil.kategori?.label ?? 'Tanpa Kategori'} | Tahun: ${mobil.tahun ?? '-'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showFormBottomSheet(context, mobil: mobil),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref, mobil),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, MobilModel mobil) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mobil'),
        content: Text('Yakin ingin menghapus mobil dengan plat ${mobil.noPlat}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(mobilControllerProvider.notifier).deleteMobil(mobil.idMobil!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showFormBottomSheet(BuildContext context, {MobilModel? mobil}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _MobilFormSheet(mobil: mobil),
  );
}

class _MobilFormSheet extends ConsumerStatefulWidget {
  final MobilModel? mobil;

  const _MobilFormSheet({this.mobil});

  @override
  ConsumerState<_MobilFormSheet> createState() => _MobilFormSheetState();
}

class _MobilFormSheetState extends ConsumerState<_MobilFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _platCtrl;
  late final TextEditingController _tahunCtrl;
  MobilKategori? _selectedKategori;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _platCtrl = TextEditingController(text: widget.mobil?.noPlat);
    _tahunCtrl = TextEditingController(text: widget.mobil?.tahun?.toString() ?? '');
    _selectedKategori = widget.mobil?.kategori;
  }

  @override
  void dispose() {
    _platCtrl.dispose();
    _tahunCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newMobil = MobilModel(
      idMobil: widget.mobil?.idMobil ?? '',
      noPlat: _platCtrl.text.trim().toUpperCase(),
      kategori: _selectedKategori,
      tahun: int.tryParse(_tahunCtrl.text.trim()),
    );

    try {
      if (widget.mobil != null) {
        await ref.read(mobilControllerProvider.notifier).updateMobil(newMobil);
      } else {
        await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
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
    final isEdit = widget.mobil != null;

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
              isEdit ? 'Edit Mobil' : 'Tambah Mobil Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _platCtrl,
              label: 'No. Plat (Contoh: B 1234 CD)',
              textCapitalization: TextCapitalization.characters,
              validator: (val) => val!.isEmpty ? 'No. Plat wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _tahunCtrl,
              label: 'Tahun Kendaraan',
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
    return DropdownButtonFormField<MobilKategori>(
      value: _selectedKategori,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
      ),
      items: MobilKategori.values.map((kategori) {
        return DropdownMenuItem(
          value: kategori,
          child: Text(kategori.label),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() => _selectedKategori = newValue);
      },
      validator: (val) => val == null ? 'Kategori wajib dipilih' : null,
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
              isEdit ? 'Simpan Perubahan' : 'Simpan Mobil',
              style: const TextStyle(color: Colors.white),
            ),
    );
  }
}