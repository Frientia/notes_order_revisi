import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mobil_model.dart';
import '../../data/repositories/mobil_repository.dart';

final mobilControllerProvider =
    StateNotifierProvider<MobilController, AsyncValue<List<MobilModel>>>((ref) {
      final repository = ref.watch(mobilRepositoryProvider);
      return MobilController(repository);
    });

class MobilController extends StateNotifier<AsyncValue<List<MobilModel>>> {
  final MobilRepository _repository;

  MobilController(this._repository) : super(const AsyncValue.loading()) {
    fetchMobil();
  }

  Future<void> fetchMobil() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getMobil());
  }

  Future<void> addMobil(MobilModel mobil) async {
    try {
      final newItem = await _repository.addMobil(mobil);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newItem]);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateMobil(MobilModel mobil) async {
    try {
      await _repository.updateMobil(mobil);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!
              .map((e) => e.idMobil == mobil.idMobil ? mobil : e)
              .toList(),
        );
      }
    } catch (e) {
      throw Exception('Gagal mengupdate mobil: $e');
    }
  }

  // UBAH: Parameter menjadi String
  Future<void> deleteMobil(String idMobil) async {
    try {
      await _repository.deleteMobil(idMobil);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((e) => e.idMobil != idMobil).toList(),
        );
      }
    } catch (e) {
      throw Exception('Gagal menghapus mobil: $e');
    }
  }
}