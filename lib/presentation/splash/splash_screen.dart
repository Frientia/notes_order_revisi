import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashReadyProvider = StateProvider<bool>((ref) => false);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      ref.read(splashReadyProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3B56B9);
    const darkTextColor = Color(0xFF25313A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.corporate_fare, 
                size: 100, 
                color: primaryColor
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'PT Lahir Barutama',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                color: darkTextColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              'Memuat sistem logistik...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            
            const SizedBox(height: 60),
            
            const CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}