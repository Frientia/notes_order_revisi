import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/barang_model.dart';
import '../../data/repositories/barang_repository.dart';

// Provider utama yang dipantau oleh UI
final barangControllerProvider = StateNotifierProvider<BarangController, AsyncValue<List<BarangModel>>>((ref) {
  final repository = ref.watch(barangRepositoryProvider);
  return BarangController(repository);
});

class BarangController extends StateNotifier<AsyncValue<List<BarangModel>>> {
  final BarangRepository _repository;

  BarangController(this._repository) : super(const AsyncValue.loading()) {
    fetchBarang(); // Otomatis ambil data saat diinisialisasi
  }

  Future<void> fetchBarang() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getBarang());
  }

  Future<void> addBarang(BarangModel barang) async {
    try {
      final newItem = await _repository.addBarang(barang);
      // Jika berhasil, sisipkan item baru ke dalam daftar yang sudah ada di layar (tanpa perlu fetch ulang)
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newItem]);
      }
    } catch (e) {
      throw Exception('Gagal menambah barang: $e');
    }
  }

  Future<void> updateBarang(BarangModel barang) async {
    try {
      await _repository.updateBarang(barang);
      // Update item di dalam memori
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((e) => e.idBarang == barang.idBarang ? barang : e).toList(),
        );
      }
    } catch (e) {
      throw Exception('Gagal mengupdate barang: $e');
    }
  }

  Future<void> deleteBarang(String idBarang) async {
    try {
      await _repository.deleteBarang(idBarang);
      // Hapus item dari memori
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((e) => e.idBarang != idBarang).toList(),
        );
      }
    } catch (e) {
      throw Exception('Gagal menghapus barang: $e');
    }
  }
}