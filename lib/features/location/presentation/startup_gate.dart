import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/location/application/city_controller.dart';
import 'package:hava/features/location/domain/city.dart';
import 'package:hava/features/location/presentation/iran_location_onboarding_screen.dart';
import 'package:hava/features/shell/presentation/main_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key});

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  bool _ready = false;
  bool _hasSelection = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('iran_location_onboarding_completed') ?? false;
    final savedCity = prefs.getString(SelectedCityController.selectedCityKey);
    final currentLocation =
        prefs.getBool(CurrentLocationController.currentLocationKey) ?? false;

    if (!completed) {
      if (!mounted) return;
      setState(() => _ready = true);
      return;
    }

    if (savedCity != null) {
      try {
        ref.read(selectedCityProvider.notifier).restore(City.decode(savedCity));
        _hasSelection = true;
      } catch (_) {
        await prefs.remove(SelectedCityController.selectedCityKey);
      }
    } else if (currentLocation) {
      ref.read(currentLocationProvider.notifier).restore(true);
      _hasSelection = true;
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  void _completeSelection() {
    if (!mounted) return;
    setState(() => _hasSelection = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const _StartupSplash();
    }

    if (!_hasSelection) {
      return IranLocationOnboardingScreen(
        onSelectionCompleted: _completeSelection,
      );
    }

    return const MainShell();
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .72, end: 1),
          duration: const Duration(milliseconds: 760),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              'assets/branding/hava_logo.png',
              width: 112,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
