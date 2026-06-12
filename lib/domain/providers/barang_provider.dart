import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/barang_model.dart';
import '../../data/repositories/barang_repository.dart';

final barangControllerProvider = StateNotifierProvider<BarangController, AsyncValue<List<BarangModel>>>((ref) {
  final repository = ref.watch(barangRepositoryProvider);
  return BarangController(repository);
});

class BarangController extends StateNotifier<AsyncValue<List<BarangModel>>> {
  final BarangRepository _repository;

  BarangController(this._repository) : super(const AsyncValue.loading()) {
    fetchBarang();
  }

  Future<void> fetchBarang() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getBarang());
  }

  Future<void> addBarang(BarangModel barang, {List<int> listIdMobilCocok = const []}) async {
    try {
      await _repository.addBarang(barang, listIdMobilCocok: listIdMobilCocok);
      await fetchBarang();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', '')); 
    }
  }

  Future<void> updateBarang(BarangModel barang, {List<int>? listIdMobilCocok}) async {
    try {
      await _repository.updateBarang(barang, listIdMobilCocok: listIdMobilCocok);
      await fetchBarang();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteBarang(int idBarang) async {
    try {
      await _repository.deleteBarang(idBarang);
      
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