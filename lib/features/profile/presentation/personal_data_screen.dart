import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/features/profile/presentation/widgets/profile_widgets.dart';

/// "Личные данные" — Figma 642:3311.
class PersonalDataScreen extends StatelessWidget {
  const PersonalDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScaffold(
      children: [
        const ProfilePageTitle('Личные данные'),
        ProfileMenu(
          tiles: [
            ProfileMenuTile(
              label: 'Имя пользователя',
              onTap: () => context.push(AppRoutes.profileName),
            ),
            ProfileMenuTile(
              label: 'Email',
              onTap: () => context.push(AppRoutes.profileEmail),
            ),
            ProfileMenuTile(
              label: 'Пароль',
              onTap: () => context.push(AppRoutes.profilePassword),
            ),
            ProfileMenuTile(
              // The mockup breaks the line after "аккаунта".
              label: 'Удаление аккаунта\nи данных',
              onTap: () => context.push(AppRoutes.profileDeleteAccount),
            ),
          ],
        ),
      ],
    );
  }
}
