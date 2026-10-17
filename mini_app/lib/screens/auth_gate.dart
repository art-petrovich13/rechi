import 'package:flutter/material.dart';
import 'package:mini_app/core/auth_service.dart';
import 'package:mini_app/screens/auth_error_screen.dart';
import 'package:mini_app/screens/home_screen.dart';
import 'package:mini_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';

/// Выбирает экран по состоянию авторизации.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AuthService>().signIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = context.watch<AuthService>();
    final Widget screen = switch (auth.status) {
      AuthStatus.idle || AuthStatus.loading => const SplashScreen(),
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.error => AuthErrorScreen(auth: auth),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey<AuthStatus>(auth.status),
        child: screen,
      ),
    );
  }
}
