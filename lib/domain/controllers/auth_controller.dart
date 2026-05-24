import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.login(email, password));
  }

  Future<void> register(String nama, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.registerPetugas(nama, email, password));
  }
}