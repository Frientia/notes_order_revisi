import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/toko_model.dart';
import '../../data/repositories/toko_repository.dart';

final tokoControllerProvider = StateNotifierProvider<TokoController, AsyncValue<List<TokoModel>>>((ref) {
  final repository = ref.watch(tokoRepositoryProvider);
  return TokoController(repository);
});

class TokoController extends StateNotifier<AsyncValue<List<TokoModel>>> {
  final TokoRepository _repository;

  TokoController(this._repository) : super(const AsyncValue.loading()) {
    fetchToko();
  }

  Future<void> fetchToko() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getToko());
  }

  Future<void> addToko(TokoModel toko) async {
    try {
      final newItem = await _repository.addToko(toko);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newItem]);
      }
    } catch (e) {
      throw Exception('Gagal menambah toko: $e');
    }
  }

  Future<void> updateToko(TokoModel toko) async {
    try {
      await _repository.updateToko(toko);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((e) => e.idToko == toko.idToko ? toko : e).toList(),
        );
      }
    } catch (e) {
      throw Exception('Gagal mengupdate toko: $e');
    }
  }

  Future<void> deleteToko(String idToko) async {
    try {
      await _repository.deleteToko(idToko);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((e) => e.idToko != idToko).toList(),
        );
      }
    } catch (e) {
      throw Exception('Gagal menghapus toko: $e');
    }
  }
}