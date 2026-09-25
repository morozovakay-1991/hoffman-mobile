import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

/// Placeholder for `/verification`, where registration lands.
// TODO(verification): replace with the graduate verification screens — a
// separate task. Until then this only keeps the post-registration flow from
// dead-ending.
class VerificationStubScreen extends StatelessWidget {
  const VerificationStubScreen({super.key});

  static const Key continueKey = ValueKey('verification-continue');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AppButton(
            key: continueKey,
            label: 'Продолжить',
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
