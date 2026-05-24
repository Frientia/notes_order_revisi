import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_order/presentation/auth/register_screen.dart';
import 'package:notes_order/presentation/auth/waiting_verification_screen.dart';
import 'package:notes_order/presentation/master_data/barang_screen.dart';
import 'package:notes_order/presentation/master_data/mobil_screen.dart';
import 'package:notes_order/presentation/master_data/toko_screen.dart';
import 'package:notes_order/presentation/transaksi/detail_riwayat_screen.dart';
import 'package:notes_order/presentation/transaksi/form_pencatatan_screen.dart';
import 'package:notes_order/presentation/transaksi/riwayat_screen.dart';

import '../../domain/providers/auth_provider.dart';
import '../../domain/providers/user_role_provider.dart';

import '../../presentation/auth/login_screen.dart';
import '../../presentation/dashboard/petugas_dashboard.dart';
import '../../presentation/dashboard/boss_dashboard.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userRoleProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final roleAsyncValue = ref.read(userRoleProvider);

      final user = authState.value;
      final isLoggedIn = user != null;
      final currentLoc = state.uri.toString();

      final isGoingToLogin = currentLoc == '/login';
      final isGoingToRegister = currentLoc == '/register';
      final isGoingToWaiting = currentLoc == '/waiting-verification';

      if (!isLoggedIn) {
        if (isGoingToLogin || isGoingToRegister) return null;
        return '/login';
      }

      if (!user.emailVerified) {
        if (isGoingToWaiting) return null;
        return '/waiting-verification';
      }

      if (roleAsyncValue.isLoading) return null;

      final role = roleAsyncValue.value;

      if (isGoingToLogin ||
          isGoingToRegister ||
          isGoingToWaiting ||
          currentLoc == '/') {
        if (role == 'petugas') return '/petugas-dashboard';
        if (role == 'boss') return '/boss-dashboard';
      }

      if (role == 'petugas' && currentLoc == '/boss-dashboard') {
        return '/petugas-dashboard';
      }

      if (role == 'boss' && currentLoc == '/petugas-dashboard') {
        return '/boss-dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/waiting-verification',
        builder: (context, state) => const WaitingVerificationScreen(),
      ),
      GoRoute(
        path: '/petugas-dashboard',
        builder: (context, state) => const PetugasDashboard(),
      ),
      GoRoute(
        path: '/boss-dashboard',
        builder: (context, state) => const BossDashboard(),
      ),
      GoRoute(
        path: '/pencatatan', 
        builder: (context, state) => const FormPencatatanScreen()
      ),
      GoRoute(
        path: '/mobil',
        builder: (context, state) => const MobilScreen(),
      ),
      GoRoute(
        path: '/barang',
        builder: (context, state) => const BarangScreen(),
      ),
      GoRoute(
        path: '/toko', 
        builder: (context, state) => const TokoScreen()
        ),
      GoRoute(
        path: '/riwayat', 
        builder: (context, state) => const RiwayatScreen()
      ),
      GoRoute(
        path: '/detail-riwayat',
        builder: (context, state) => DetailRiwayatScreen(idPencatatan: state.extra as int),
      ),
    ],
  );
});
